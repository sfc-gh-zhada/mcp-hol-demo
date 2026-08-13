-- Load the public Banking77 data into B77_TRAIN, B77_PROBE, and B77_TEST first.
-- Each table must contain TEXT and LABEL columns.

DROP MODEL IF EXISTS MCP_HOL.SUPPORT.SUPPORT_INTENT_8B;

SELECT SNOWFLAKE.CORTEX.FINETUNE(
  'CREATE',
  'MCP_HOL.SUPPORT.SUPPORT_INTENT_8B',
  'llama3.1-8b',
  $$SELECT TEXT AS prompt, LABEL AS completion FROM MCP_HOL.SUPPORT.B77_TRAIN$$,
  $$SELECT TEXT AS prompt, LABEL AS completion FROM MCP_HOL.SUPPORT.B77_PROBE$$
);

-- Poll the returned job ID until the status is SUCCESS before continuing:
-- SELECT SNOWFLAKE.CORTEX.FINETUNE('DESCRIBE', '<job_id>');

CREATE OR REPLACE PROCEDURE MCP_HOL.SUPPORT.CLASSIFY_INTENT_PROC(MESSAGE STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = 3.11
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run'
EXECUTE AS OWNER
AS $$
def run(session, message):
    row = session.sql(
        "SELECT SNOWFLAKE.CORTEX.COMPLETE('MCP_HOL.SUPPORT.SUPPORT_INTENT_8B', ?)",
        params=[message or '']).collect()
    raw = (row[0][0] or '').strip().lower()
    import re
    match = re.search(r'[a-z_]{3,}', raw)
    return match.group(0) if match else raw
$$;

GRANT USAGE ON PROCEDURE MCP_HOL.SUPPORT.CLASSIFY_INTENT_PROC(VARCHAR) TO ROLE CUSTOMER_AGENT;