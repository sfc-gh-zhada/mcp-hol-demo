-- ============================================================
-- Ticket surface + intent-driven routing
-- file_ticket takes the intent label (produced by classify_intent) and routes
-- the incident using a POLICY table (INTENT_ROUTING) — queue, priority, SLA the
-- model can't invent. This is why classify_intent is necessary in the live flow:
-- file_ticket REQUIRES a valid intent to route the case.
-- Self-contained: no external calls, owner's rights.
-- ============================================================
CREATE OR REPLACE SEQUENCE MCP_HOL.SUPPORT.TICKET_SEQ START = 1001 INCREMENT = 1;

CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.TICKETS (
  INCIDENT_NUMBER  STRING,       -- ServiceNow-style incident id, e.g. INC0001001
  ORDER_ID         STRING,
  ISSUE            STRING,
  INTENT           STRING,       -- from classify_intent (fine-tuned model)
  QUEUE            STRING,       -- routed queue (policy)
  PRIORITY         STRING,       -- routed priority (policy)
  STATUS           STRING,
  CREATED_AT       TIMESTAMP_NTZ
);

-- Example historical incidents so the log isn't empty in the demo.
-- INC numbers stay below the sequence start (1001) so they never collide with
-- tickets filed live by file_ticket (which start at INC0001001).
-- QUEUE/PRIORITY here match the INTENT_ROUTING policy below.
INSERT INTO MCP_HOL.SUPPORT.TICKETS
  (INCIDENT_NUMBER, ORDER_ID, ISSUE, INTENT, QUEUE, PRIORITY, STATUS, CREATED_AT) VALUES
  ('INC0000991', 'ORD-10002', 'Sole started splitting after two short runs',            'DEFECTIVE_ITEM',   'Product Quality',   'P2', 'Resolved',    DATEADD('day', -15, CURRENT_TIMESTAMP())),
  ('INC0000993', 'ORD-10001', 'Love the jacket — incredibly warm on the summit',        'GENERAL_FEEDBACK', 'Customer Care',     'P4', 'Resolved',    DATEADD('day', -11, CURRENT_TIMESTAMP())),
  ('INC0000995', 'ORD-10005', 'Boots run half a size small, need the next size up',      'SIZING_EXCHANGE',  'Returns & Refunds', 'P3', 'Resolved',    DATEADD('day',  -8, CURRENT_TIMESTAMP())),
  ('INC0000996', 'ORD-10006', 'Rain shell has been in transit for two weeks, still not here', 'SHIPPING_DELAY', 'Logistics',    'P3', 'In Progress', DATEADD('day',  -4, CURRENT_TIMESTAMP())),
  ('INC0000998', 'ORD-10008', 'Shoes rub my heel — would like to return them',           'RETURN_REFUND',    'Returns & Refunds', 'P2', 'In Progress', DATEADD('day',  -2, CURRENT_TIMESTAMP())),
  ('INC0000999', 'ORD-10009', 'Just checking where my jacket is',                        'ORDER_STATUS',     'Logistics',         'P4', 'New',         DATEADD('hour', -6, CURRENT_TIMESTAMP()));

-- Routing policy: intent label -> support queue + priority + SLA (company policy)
CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.INTENT_ROUTING (
  INTENT     STRING,
  QUEUE      STRING,
  PRIORITY   STRING,
  SLA_HOURS  INT
);
INSERT INTO MCP_HOL.SUPPORT.INTENT_ROUTING (INTENT, QUEUE, PRIORITY, SLA_HOURS) VALUES
  ('DEFECTIVE_ITEM',   'Product Quality',    'P2', 8),
  ('RETURN_REFUND',    'Returns & Refunds',  'P2', 8),
  ('SHIPPING_DELAY',   'Logistics',          'P3', 12),
  ('SIZING_EXCHANGE',  'Returns & Refunds',  'P3', 24),
  ('ORDER_STATUS',     'Logistics',          'P4', 24),
  ('GENERAL_FEEDBACK', 'Customer Care',      'P4', 48);

-- Drop the old 2-arg signature so the tool resolves to the routed version only.
DROP PROCEDURE IF EXISTS MCP_HOL.SUPPORT.FILE_TICKET(VARCHAR, VARCHAR);

CREATE OR REPLACE PROCEDURE MCP_HOL.SUPPORT.FILE_TICKET(ORDER_ID STRING, ISSUE STRING, INTENT STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = 3.11
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run'
EXECUTE AS OWNER
AS
$$
def run(session, order_id, issue, intent):
    label = (intent or '').strip().upper()
    row = session.sql(
        "SELECT QUEUE, PRIORITY, SLA_HOURS FROM MCP_HOL.SUPPORT.INTENT_ROUTING WHERE INTENT = ?",
        params=[label]).collect()
    if row:
        queue, priority, sla = row[0][0], row[0][1], row[0][2]
    else:
        # Unknown / missing intent -> cannot route to a specialist queue.
        label, queue, priority, sla = 'UNCLASSIFIED', 'General Triage', 'P3', 24
    seq = session.sql('SELECT MCP_HOL.SUPPORT.TICKET_SEQ.NEXTVAL').collect()[0][0]
    inc = 'INC' + str(seq).zfill(7)
    session.sql(
        'INSERT INTO MCP_HOL.SUPPORT.TICKETS '
        '(INCIDENT_NUMBER, ORDER_ID, ISSUE, INTENT, QUEUE, PRIORITY, STATUS, CREATED_AT) '
        "VALUES (?, ?, ?, ?, ?, ?, 'New', CURRENT_TIMESTAMP())",
        params=[inc, order_id, issue, label, queue, priority]).collect()
    return ('Created ServiceNow incident ' + inc + ' for order ' + str(order_id)
            + ' — classified as ' + label + ', routed to the ' + queue
            + ' queue at priority ' + priority + ' (SLA ' + str(sla) + 'h). '
            + 'A specialist will follow up shortly.')
$$;

GRANT USAGE ON PROCEDURE MCP_HOL.SUPPORT.FILE_TICKET(VARCHAR, VARCHAR, VARCHAR) TO ROLE CUSTOMER_AGENT;
