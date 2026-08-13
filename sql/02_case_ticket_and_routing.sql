CREATE OR REPLACE SEQUENCE MCP_HOL.SUPPORT.TICKET_SEQ START = 1001 INCREMENT = 1;

CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.TICKETS (
  INCIDENT_NUMBER  STRING,
  REF_ID           STRING,
  ISSUE            STRING,
  INTENT           STRING,
  QUEUE            STRING,
  PRIORITY         STRING,
  STATUS           STRING,
  CREATED_AT       TIMESTAMP_NTZ
);

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
  CASE WHEN queue = 'Cards & Fraud' THEN 'P1'
       WHEN queue = 'Payments & Transfers' THEN 'P2'
       WHEN queue = 'General Support' THEN 'P4'
       ELSE 'P3' END,
  CASE WHEN queue = 'Cards & Fraud' THEN 2
       WHEN queue = 'Payments & Transfers' THEN 8
       WHEN queue = 'General Support' THEN 48
       ELSE 24 END
FROM (
  SELECT DISTINCT LABEL AS label,
    CASE
      WHEN LABEL ILIKE '%lost%' OR LABEL ILIKE '%stolen%' OR LABEL ILIKE '%compromised%'
        OR LABEL ILIKE '%swallow%' OR LABEL ILIKE '%declined_transfer%' THEN 'Cards & Fraud'
      WHEN LABEL ILIKE '%transfer%' OR LABEL ILIKE '%top_up%' OR LABEL ILIKE '%topping_up%'
        OR LABEL ILIKE '%payment%' OR LABEL ILIKE '%direct_debit%' OR LABEL ILIKE '%beneficiary%'
        OR LABEL ILIKE '%pending%' OR LABEL ILIKE '%transaction%' OR LABEL ILIKE '%declined%'
        OR LABEL ILIKE '%reverted%' OR LABEL ILIKE '%received%' THEN 'Payments & Transfers'
      WHEN LABEL ILIKE '%cash%' OR LABEL ILIKE '%atm%' THEN 'Cash & ATM'
      WHEN LABEL ILIKE '%exchange%' OR LABEL ILIKE '%fx%' OR LABEL ILIKE '%currency%'
        OR LABEL ILIKE '%crypto%' OR LABEL ILIKE '%fiat%' THEN 'FX & Exchange'
      WHEN LABEL ILIKE '%fee%' OR LABEL ILIKE '%charge%' OR LABEL ILIKE '%wrong_amount%'
        OR LABEL ILIKE '%extra%' OR LABEL ILIKE '%rate%' THEN 'Fees & Charges'
      WHEN LABEL ILIKE '%card%' THEN 'Cards'
      WHEN LABEL ILIKE '%verify%' OR LABEL ILIKE '%identity%' OR LABEL ILIKE '%pin%'
        OR LABEL ILIKE '%passcode%' OR LABEL ILIKE '%age_limit%' OR LABEL ILIKE '%country%'
        OR LABEL ILIKE '%unable_to_verify%' OR LABEL ILIKE '%verification%' THEN 'Account & Identity'
      ELSE 'General Support'
    END AS queue
  FROM MCP_HOL.SUPPORT.B77_TRAIN
);

CREATE OR REPLACE PROCEDURE MCP_HOL.SUPPORT.FILE_TICKET(REF_ID STRING, ISSUE STRING, INTENT STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = 3.11
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run'
EXECUTE AS OWNER
AS $$
def run(session, ref_id, issue, intent):
    label = (intent or '').strip().lower()
    row = session.sql(
        'SELECT QUEUE, PRIORITY, SLA_HOURS FROM MCP_HOL.SUPPORT.INTENT_ROUTING WHERE INTENT = ?',
        params=[label]).collect()
    if row:
        queue, priority, sla = row[0][0], row[0][1], row[0][2]
    else:
        label, queue, priority, sla = 'unclassified', 'General Support', 'P4', 48
    sequence_value = session.sql('SELECT MCP_HOL.SUPPORT.TICKET_SEQ.NEXTVAL').collect()[0][0]
    incident_number = 'INC' + str(sequence_value).zfill(7)
    session.sql(
        'INSERT INTO MCP_HOL.SUPPORT.TICKETS '
        '(INCIDENT_NUMBER, REF_ID, ISSUE, INTENT, QUEUE, PRIORITY, STATUS, CREATED_AT) '
        "VALUES (?, ?, ?, ?, ?, ?, 'New', CURRENT_TIMESTAMP())",
        params=[incident_number, ref_id, issue, label, queue, priority]).collect()
    return ('Created incident ' + incident_number + ' for case ' + str(ref_id)
            + ', classified as ' + label + ', routed to the ' + queue
            + ' queue at priority ' + priority + ' (SLA ' + str(sla) + 'h).')
$$;

GRANT USAGE ON PROCEDURE MCP_HOL.SUPPORT.FILE_TICKET(VARCHAR, VARCHAR, VARCHAR) TO ROLE CUSTOMER_AGENT;