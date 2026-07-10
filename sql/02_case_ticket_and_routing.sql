-- ============================================================
-- 02_case_ticket_and_routing.sql   (fintech pivot)
-- Ticket surface + intent-driven routing for the neobank support desk.
-- file_ticket takes the intent label (produced by classify_intent -> the 77-way
-- Banking77 fine-tune) and routes the incident using a POLICY table
-- (INTENT_ROUTING) -- queue, priority, SLA the model can't invent. This is why
-- classify_intent is load-bearing: file_ticket REQUIRES a valid intent to route.
-- Self-contained: no external calls, owner's rights.
-- ============================================================
CREATE OR REPLACE SEQUENCE MCP_HOL.SUPPORT.TICKET_SEQ START = 1001 INCREMENT = 1;

CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.TICKETS (
  INCIDENT_NUMBER  STRING,       -- ServiceNow-style incident id, e.g. INC0001001
  REF_ID           STRING,       -- related case/transaction reference
  ISSUE            STRING,
  INTENT           STRING,       -- from classify_intent (fine-tuned model), e.g. card_arrival
  QUEUE            STRING,       -- routed queue (policy)
  PRIORITY         STRING,       -- routed priority (policy)
  STATUS           STRING,
  CREATED_AT       TIMESTAMP_NTZ
);

-- Example historical incidents so the log isn't empty. INC numbers stay below the
-- sequence start (1001) so they never collide with tickets filed live.
INSERT INTO MCP_HOL.SUPPORT.TICKETS
  (INCIDENT_NUMBER, REF_ID, ISSUE, INTENT, QUEUE, PRIORITY, STATUS, CREATED_AT) VALUES
  ('INC0000991', 'CASE-10004', 'Reported card lost, needs replacement urgently',    'lost_or_stolen_card',   'Cards & Fraud',        'P1', 'Resolved',    DATEADD('day', -15, CURRENT_TIMESTAMP())),
  ('INC0000993', 'CASE-10002', 'International transfer still pending after 2 days',  'transfer_not_received_by_recipient', 'Payments & Transfers', 'P2', 'In Progress', DATEADD('day', -3, CURRENT_TIMESTAMP())),
  ('INC0000995', 'CASE-10007', 'Card payment declined at checkout',                 'declined_card_payment', 'Payments & Transfers', 'P2', 'In Progress', DATEADD('day', -2, CURRENT_TIMESTAMP())),
  ('INC0000996', 'CASE-10006', 'Question about weekend exchange rate',              'exchange_rate',         'FX & Exchange',        'P3', 'Resolved',    DATEADD('day', -6, CURRENT_TIMESTAMP())),
  ('INC0000998', 'CASE-10008', 'Unexpected fee on statement',                       'extra_charge_on_statement', 'Fees & Charges',   'P3', 'In Progress', DATEADD('day', -1, CURRENT_TIMESTAMP())),
  ('INC0000999', 'CASE-10001', 'Checking when the new card will arrive',            'card_arrival',          'Cards',                'P3', 'New',         DATEADD('hour', -6, CURRENT_TIMESTAMP()));

-- Routing policy: intent label -> support queue + priority + SLA (bank policy).
-- Generated for ALL 77 Banking77 intents by rule, so every label the fine-tune
-- can emit routes somewhere. Adjacent intents route to DIFFERENT teams (e.g.
-- card_arrival -> Cards, lost_or_stolen_card -> Cards & Fraud/P1), which is why
-- getting the intent right (the fine-tune) matters.
CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.INTENT_ROUTING (
  INTENT     STRING,
  QUEUE      STRING,
  PRIORITY   STRING,
  SLA_HOURS  INT
);
INSERT INTO MCP_HOL.SUPPORT.INTENT_ROUTING (INTENT, QUEUE, PRIORITY, SLA_HOURS)
SELECT
  label,
  queue,
  CASE WHEN queue = 'Cards & Fraud'        THEN 'P1'
       WHEN queue = 'Payments & Transfers' THEN 'P2'
       WHEN queue = 'General Support'      THEN 'P4'
       ELSE 'P3' END AS priority,
  CASE WHEN queue = 'Cards & Fraud'        THEN 2
       WHEN queue = 'Payments & Transfers' THEN 8
       WHEN queue = 'General Support'      THEN 48
       ELSE 24 END AS sla_hours
FROM (
  SELECT DISTINCT LABEL AS label,
    CASE
      WHEN LABEL ILIKE '%lost%' OR LABEL ILIKE '%stolen%' OR LABEL ILIKE '%compromised%'
        OR LABEL ILIKE '%swallow%' OR LABEL ILIKE '%declined_transfer%'                 THEN 'Cards & Fraud'
      WHEN LABEL ILIKE '%transfer%' OR LABEL ILIKE '%top_up%' OR LABEL ILIKE '%topping_up%'
        OR LABEL ILIKE '%payment%' OR LABEL ILIKE '%direct_debit%' OR LABEL ILIKE '%beneficiary%'
        OR LABEL ILIKE '%pending%' OR LABEL ILIKE '%transaction%' OR LABEL ILIKE '%declined%'
        OR LABEL ILIKE '%reverted%' OR LABEL ILIKE '%received%'                          THEN 'Payments & Transfers'
      WHEN LABEL ILIKE '%cash%' OR LABEL ILIKE '%atm%'                                    THEN 'Cash & ATM'
      WHEN LABEL ILIKE '%exchange%' OR LABEL ILIKE '%fx%' OR LABEL ILIKE '%currency%'
        OR LABEL ILIKE '%crypto%' OR LABEL ILIKE '%fiat%'                                 THEN 'FX & Exchange'
      WHEN LABEL ILIKE '%fee%' OR LABEL ILIKE '%charge%' OR LABEL ILIKE '%wrong_amount%'
        OR LABEL ILIKE '%extra%' OR LABEL ILIKE '%rate%'                                  THEN 'Fees & Charges'
      WHEN LABEL ILIKE '%card%'                                                           THEN 'Cards'
      WHEN LABEL ILIKE '%verify%' OR LABEL ILIKE '%identity%' OR LABEL ILIKE '%pin%'
        OR LABEL ILIKE '%passcode%' OR LABEL ILIKE '%age_limit%' OR LABEL ILIKE '%country%'
        OR LABEL ILIKE '%unable_to_verify%' OR LABEL ILIKE '%verification%'               THEN 'Account & Identity'
      ELSE 'General Support'
    END AS queue
  FROM MCP_HOL.SUPPORT.B77_TRAIN
);

-- Drop any old signature so the tool resolves to the routed version only.
DROP PROCEDURE IF EXISTS MCP_HOL.SUPPORT.FILE_TICKET(VARCHAR, VARCHAR);

CREATE OR REPLACE PROCEDURE MCP_HOL.SUPPORT.FILE_TICKET(REF_ID STRING, ISSUE STRING, INTENT STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = 3.11
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run'
EXECUTE AS OWNER
AS
$$
def run(session, ref_id, issue, intent):
    # Banking77 labels are lowercase_with_underscores -> match the routing policy as-is.
    label = (intent or '').strip().lower()
    row = session.sql(
        "SELECT QUEUE, PRIORITY, SLA_HOURS FROM MCP_HOL.SUPPORT.INTENT_ROUTING WHERE INTENT = ?",
        params=[label]).collect()
    if row:
        queue, priority, sla = row[0][0], row[0][1], row[0][2]
    else:
        # Unknown / missing intent -> cannot route to a specialist queue.
        label, queue, priority, sla = 'unclassified', 'General Support', 'P4', 48
    seq = session.sql('SELECT MCP_HOL.SUPPORT.TICKET_SEQ.NEXTVAL').collect()[0][0]
    inc = 'INC' + str(seq).zfill(7)
    session.sql(
        'INSERT INTO MCP_HOL.SUPPORT.TICKETS '
        '(INCIDENT_NUMBER, REF_ID, ISSUE, INTENT, QUEUE, PRIORITY, STATUS, CREATED_AT) '
        "VALUES (?, ?, ?, ?, ?, ?, 'New', CURRENT_TIMESTAMP())",
        params=[inc, ref_id, issue, label, queue, priority]).collect()
    return ('Created incident ' + inc + ' for case ' + str(ref_id)
            + ' — classified as ' + label + ', routed to the ' + queue
            + ' queue at priority ' + priority + ' (SLA ' + str(sla) + 'h). '
            + 'A specialist will follow up shortly.')
$$;

GRANT USAGE ON PROCEDURE MCP_HOL.SUPPORT.FILE_TICKET(VARCHAR, VARCHAR, VARCHAR) TO ROLE CUSTOMER_AGENT;
