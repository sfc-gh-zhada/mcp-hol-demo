-- === Reframe: refund-approval CASE model + Zendesk external connection ===

-- Case table (a case pending human approval, not an auto-refund)
CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.TICKETS (
  TICKET_ID          STRING,
  ORDER_ID           STRING,
  ISSUE              STRING,
  RECOMMENDED_REFUND NUMBER(10,2),
  STATUS             STRING,            -- PENDING_APPROVAL -> APPROVED
  EXTERNAL_CASE      STRING,            -- Zendesk case id when reachable
  CREATED_AT         TIMESTAMP_NTZ,
  APPROVED_BY        STRING,
  APPROVED_AT        TIMESTAMP_NTZ
);

-- Swap external access from ServiceNow to Zendesk (CX case system)
DROP EXTERNAL ACCESS INTEGRATION IF EXISTS SERVICENOW_MCP_HOL_INT;
DROP SECRET IF EXISTS MCP_HOL.SUPPORT.SERVICENOW_CRED;
DROP NETWORK RULE IF EXISTS MCP_HOL.SUPPORT.SERVICENOW_RULE;

CREATE OR REPLACE NETWORK RULE MCP_HOL.SUPPORT.ZENDESK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('acme.zendesk.com');   -- <-- your Zendesk subdomain

CREATE OR REPLACE SECRET MCP_HOL.SUPPORT.ZENDESK_CRED
  TYPE = PASSWORD
  USERNAME = 'agent@acme.com/token'     -- Zendesk email/token auth
  PASSWORD = 'REPLACE_WITH_ZENDESK_API_TOKEN';

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION ZENDESK_MCP_HOL_INT
  ALLOWED_NETWORK_RULES = (MCP_HOL.SUPPORT.ZENDESK_RULE)
  ALLOWED_AUTHENTICATION_SECRETS = (MCP_HOL.SUPPORT.ZENDESK_CRED)
  ENABLED = TRUE;

-- Governed action: open a refund-approval CASE (agent proposes; human approves)
CREATE OR REPLACE PROCEDURE MCP_HOL.SUPPORT.CREATE_TICKET(ORDER_ID STRING, ISSUE STRING, RECOMMENDED_REFUND FLOAT)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = 3.11
HANDLER = 'run'
EXTERNAL_ACCESS_INTEGRATIONS = (ZENDESK_MCP_HOL_INT)
PACKAGES = ('snowflake-snowpark-python','requests')
SECRETS = ('cred' = MCP_HOL.SUPPORT.ZENDESK_CRED)
AS
$$
import _snowflake, requests

ZD_HOST = 'acme.zendesk.com'  # <-- your Zendesk subdomain

def run(session, order_id, issue, recommended_refund):
    tid = 'CASE-' + str(session.sql('SELECT MCP_HOL.SUPPORT.TICKET_SEQ.NEXTVAL').collect()[0][0])
    ext = None
    try:
        c = _snowflake.get_username_password('cred')
        resp = requests.post('https://{}/api/v2/tickets.json'.format(ZD_HOST),
            auth=(c.username, c.password),
            headers={'Content-Type':'application/json'},
            json={'ticket': {
                'subject': 'Refund approval: order ' + str(order_id),
                'comment': {'body': str(issue) + ' | Recommended refund: $' + str(recommended_refund) + ' | Status: PENDING_APPROVAL'}
            }},
            timeout=10)
        if resp.status_code in (200, 201):
            ext = 'ZD-' + str(resp.json().get('ticket', {}).get('id'))
    except Exception:
        ext = None
    ext_sql = 'NULL' if not ext else "'" + str(ext).replace("'", "''") + "'"
    session.sql(
        'INSERT INTO MCP_HOL.SUPPORT.TICKETS '
        '(TICKET_ID, ORDER_ID, ISSUE, RECOMMENDED_REFUND, STATUS, EXTERNAL_CASE, CREATED_AT) '
        'VALUES (?, ?, ?, ?, ' + "'PENDING_APPROVAL', " + ext_sql + ', CURRENT_TIMESTAMP())',
        params=[tid, order_id, issue, recommended_refund]).collect()
    tail = (' Zendesk case ' + ext + '.') if ext else ' (Zendesk not reachable yet - recorded in Snowflake.)'
    return ('Opened refund-approval case ' + tid + ' for order ' + str(order_id) +
            ', recommending a $' + str(recommended_refund) + ' refund - PENDING human approval.' + tail)
$$;

-- Human-in-the-loop: approving the case is what releases the refund (downstream)
CREATE OR REPLACE PROCEDURE MCP_HOL.SUPPORT.APPROVE_CASE(TICKET_ID STRING)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
  amt NUMBER(10,2);
  ord STRING;
BEGIN
  SELECT RECOMMENDED_REFUND, ORDER_ID INTO :amt, :ord
    FROM MCP_HOL.SUPPORT.TICKETS WHERE TICKET_ID = :TICKET_ID;
  UPDATE MCP_HOL.SUPPORT.TICKETS
     SET STATUS = 'APPROVED', APPROVED_BY = CURRENT_USER(), APPROVED_AT = CURRENT_TIMESTAMP()
   WHERE TICKET_ID = :TICKET_ID;
  RETURN 'Case ' || :TICKET_ID || ' approved by ' || CURRENT_USER() ||
         ' - $' || :amt || ' refund released for order ' || :ord || '.';
END;
$$;
