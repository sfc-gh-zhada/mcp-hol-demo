-- ============================================================
-- 06_finetune_intent.sql   (order-dependent; run AFTER 01-05)
-- The fine-tuned classifier at the center of the demo: a model whose decision
-- boundary you OWN, that beats frontier models a business could otherwise reach.
--
--   Base model : llama3.1-8b  (durable base; not on the 2026 deprecation lists)
--   Task       : Banking77 -- 77 real neobank customer-support intents
--                (PolyAI, CC-BY-4.0). High cardinality + near-identical classes
--                (e.g. card_arrival vs card_delivery_estimate vs
--                lost_or_stolen_card) whose boundaries live in labeled history,
--                not in a promptable rule.
--   Produces   : MCP_HOL.SUPPORT.SUPPORT_INTENT_8B         (fine-tuned model)
--                MCP_HOL.SUPPORT.CLASSIFY_INTENT_PROC(msg)  (the MCP tool wrapper)
--
-- WHY A FINE-TUNE IS NECESSARY (the demo thesis, and it is MEASURED below):
--   Hand a frontier model the FULL 77-label list and it still confuses adjacent
--   intents -- because telling apart "my card hasn't arrived" (card_arrival) from
--   "when will my card arrive" (card_delivery_estimate) is a convention learned
--   from thousands of tickets, not a describable rule. A fine-tuned 8B trained on
--   that history wins: ~90% probe / 91% full-test vs frontier ~76-78%. You cannot
--   fine-tune a closed frontier API; you CAN fine-tune on your governed Snowflake
--   data and expose it as one governed MCP tool.
--
-- ASYNC/GC: FINETUNE('CREATE') is long-running -> keep it OUT of the attendee
-- Run-All path. Fine-tune models are garbage-collected over ~days/weeks -> create
-- CLOSE to the webinar and re-verify callability the day before.
-- ============================================================

-- ------------------------------------------------------------
-- Step 1  Data. Banking77, staged in this schema so the demo is self-contained.
--   B77_TRAIN (10,003) / B77_TEST (3,080) / B77_PROBE (154, all 77 intents).
-- (Copied from AI_SAFETY_RESEARCH.BANKING_INTENT; columns TEXT, LABEL.)
-- ------------------------------------------------------------
-- CREATE TABLE ... AS SELECT * FROM AI_SAFETY_RESEARCH.BANKING_INTENT.B77_*  (done in setup)
SELECT LABEL, COUNT(*) AS n FROM MCP_HOL.SUPPORT.B77_TRAIN GROUP BY LABEL ORDER BY n DESC LIMIT 10;

-- ------------------------------------------------------------
-- Step 2  Kick off the fine-tune (ASYNC -> returns a job id).
-- Prompt = the BARE customer message; completion = the intent label. The task and
-- the 77-way label space live in the WEIGHTS -> inference needs zero prompt
-- engineering. Train-time prompt == serve-time prompt == the bare message.
-- ------------------------------------------------------------
DROP MODEL IF EXISTS MCP_HOL.SUPPORT.SUPPORT_INTENT_8B;

SELECT SNOWFLAKE.CORTEX.FINETUNE(
  'CREATE',
  'MCP_HOL.SUPPORT.SUPPORT_INTENT_8B',
  'llama3.1-8b',
  $$SELECT TEXT AS prompt, LABEL AS completion FROM MCP_HOL.SUPPORT.B77_TRAIN$$,
  $$SELECT TEXT AS prompt, LABEL AS completion FROM MCP_HOL.SUPPORT.B77_PROBE$$
);
-- Poll to completion (replace <job_id> with the id returned above):
--   SELECT SNOWFLAKE.CORTEX.FINETUNE('DESCRIBE', '<job_id>');
-- Wait for "status": "SUCCESS" before the model is callable (~25-30 min for 10k rows).

-- ------------------------------------------------------------
-- Step 3  The MCP tool wrapper -- a STORED PROCEDURE (EXECUTE AS OWNER), because a
-- fine-tuned model is reachable through the managed MCP server ONLY in a normal
-- owner's-rights session. Bare message in -> one banking intent label out.
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS MCP_HOL.SUPPORT.CLASSIFY_INTENT(VARCHAR);

CREATE OR REPLACE PROCEDURE MCP_HOL.SUPPORT.CLASSIFY_INTENT_PROC(MESSAGE STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = 3.11
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run'
EXECUTE AS OWNER
AS $$
def run(session, message):
    # Bare message -> the fine-tune emits one Banking77 label (lowercase_underscore).
    row = session.sql(
        "SELECT SNOWFLAKE.CORTEX.COMPLETE('MCP_HOL.SUPPORT.SUPPORT_INTENT_8B', ?)",
        params=[message or '']).collect()
    raw = (row[0][0] or '').strip().lower()
    import re
    m = re.search(r'[a-z_]{3,}', raw)  # strip any stray punctuation/prefix
    return m.group(0) if m else raw
$$;

-- input: a customer message   ->   output: one banking intent label
CALL MCP_HOL.SUPPORT.CLASSIFY_INTENT_PROC('My card still has not arrived after two weeks.');  -- expect card_arrival

-- ------------------------------------------------------------
-- Step 4  FAIR BENCHMARK: fine-tune vs current frontier models GIVEN THE FULL
-- 77-LABEL LIST (the strongest honest setup for the frontier models). The
-- fine-tune gets only the bare message. Exact-match after LOWER/TRIM.
-- Frontier callable here: claude-4-sonnet, openai-gpt-4.1. (Runs in SQL, not via
-- MCP, so AI_COMPLETE on the fine-tune is fine here.)
-- ------------------------------------------------------------
SET LABELS = (SELECT LISTAGG(DISTINCT LABEL, ', ') WITHIN GROUP (ORDER BY LABEL) FROM MCP_HOL.SUPPORT.B77_TRAIN);

WITH base AS (
  SELECT
    LOWER(TRIM(LABEL)) AS truth,
    LOWER(TRIM(SNOWFLAKE.CORTEX.COMPLETE('MCP_HOL.SUPPORT.SUPPORT_INTENT_8B', TEXT))) AS ft_raw,
    LOWER(TRIM(AI_COMPLETE('claude-4-sonnet',
      'You are an intent classifier for a neobank''s customer support. '
      || 'Classify the message into exactly ONE of these 77 intents. '
      || 'Reply with ONLY the intent label (lowercase, underscores), nothing else.' || CHR(10)
      || 'Intents: ' || $LABELS || CHR(10) || CHR(10) || 'Message: ' || TEXT))) AS sonnet_raw,
    LOWER(TRIM(AI_COMPLETE('openai-gpt-4.1',
      'You are an intent classifier for a neobank''s customer support. '
      || 'Classify the message into exactly ONE of these 77 intents. '
      || 'Reply with ONLY the intent label (lowercase, underscores), nothing else.' || CHR(10)
      || 'Intents: ' || $LABELS || CHR(10) || CHR(10) || 'Message: ' || TEXT))) AS gpt_raw
  FROM MCP_HOL.SUPPORT.B77_PROBE
),
norm AS (
  SELECT truth,
    REGEXP_SUBSTR(ft_raw,     '[a-z_]{3,}', 1, GREATEST(REGEXP_COUNT(ft_raw,     '[a-z_]{3,}'),1)) AS ft,
    REGEXP_SUBSTR(sonnet_raw, '[a-z_]{3,}', 1, GREATEST(REGEXP_COUNT(sonnet_raw, '[a-z_]{3,}'),1)) AS sonnet,
    REGEXP_SUBSTR(gpt_raw,    '[a-z_]{3,}', 1, GREATEST(REGEXP_COUNT(gpt_raw,    '[a-z_]{3,}'),1)) AS gpt
  FROM base
)
SELECT
  COUNT(*)                                          AS probe_rows,
  ROUND(AVG(IFF(ft     = truth,1,0))*100,1)         AS ft_pct,
  ROUND(AVG(IFF(sonnet = truth,1,0))*100,1)         AS sonnet_pct,
  ROUND(AVG(IFF(gpt    = truth,1,0))*100,1)         AS gpt_pct
FROM norm;

-- Robust full-test-set number for the fine-tune (3,080 rows; frontier omitted for cost):
WITH s AS (
  SELECT LOWER(TRIM(LABEL)) AS truth,
    REGEXP_SUBSTR(LOWER(TRIM(SNOWFLAKE.CORTEX.COMPLETE('MCP_HOL.SUPPORT.SUPPORT_INTENT_8B', TEXT))),'[a-z_]{3,}') AS pred
  FROM MCP_HOL.SUPPORT.B77_TEST
)
SELECT COUNT(*) AS test_rows, ROUND(AVG(IFF(pred=truth,1,0))*100,1) AS ft_fulltest_pct FROM s;

-- ------------------------------------------------------------
-- Pre-webinar callability check (RUN THE DAY BEFORE). Re-run this whole script if
-- it errors with "model ... is unavailable" (fine-tunes are GC'd over ~days).
-- ------------------------------------------------------------
--   CALL MCP_HOL.SUPPORT.CLASSIFY_INTENT_PROC('my card still has not arrived');  -- expect card_arrival
