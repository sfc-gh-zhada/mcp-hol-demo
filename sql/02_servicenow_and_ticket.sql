-- Tickets table + sequence (local source of truth for the demo)
CREATE OR REPLACE SEQUENCE MCP_HOL.SUPPORT.TICKET_SEQ START = 1001 INCREMENT = 1;

CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.TICKETS (
  TICKET_ID           STRING,
  ORDER_ID            STRING,
  ISSUE               STRING,
  SERVICENOW_INCIDENT STRING,
  STATUS              STRING,
  CREATED_AT          TIMESTAMP_NTZ
);

-- === ServiceNow External Access scaffolding ===
-- NOTE: host + secret are PLACEHOLDERS. Update SERVICENOW_RULE VALUE_LIST,
-- SERVICENOW_CRED PASSWORD, and SN_HOST in the procedure to your live dev instance.
CREATE OR REPLACE NETWORK RULE MCP_HOL.SUPPORT.SERVICENOW_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('dev123456.service-now.com');

CREATE OR REPLACE SECRET MCP_HOL.SUPPORT.SERVICENOW_CRED
  TYPE = PASSWORD
  USERNAME = 'admin'
  PASSWORD = 'REPLACE_WITH_SERVICENOW_PASSWORD';

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION SERVICENOW_MCP_HOL_INT
  ALLOWED_NETWORK_RULES = (MCP_HOL.SUPPORT.SERVICENOW_RULE)
  ALLOWED_AUTHENTICATION_SECRETS = (MCP_HOL.SUPPORT.SERVICENOW_CRED)
  ENABLED = TRUE;

-- === Hybrid ticket procedure: always writes local TICKET, POSTs to ServiceNow when reachable ===
CREATE OR REPLACE PROCEDURE MCP_HOL.SUPPORT.CREATE_TICKET(ORDER_ID STRING, ISSUE STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = 3.11
HANDLER = 'run'
EXTERNAL_ACCESS_INTEGRATIONS = (SERVICENOW_MCP_HOL_INT)
PACKAGES = ('snowflake-snowpark-python','requests')
SECRETS = ('cred' = MCP_HOL.SUPPORT.SERVICENOW_CRED)
AS
$$
import _snowflake, requests

SN_HOST = "dev123456.service-now.com"  # <-- update to your ServiceNow dev instance

def run(session, order_id, issue):
    tid = "TCK-" + str(session.sql("SELECT MCP_HOL.SUPPORT.TICKET_SEQ.NEXTVAL").collect()[0][0])
    inc = None
    try:
        c = _snowflake.get_username_password('cred')
        resp = requests.post(
            "https://{}/api/now/table/incident".format(SN_HOST),
            auth=(c.username, c.password),
            headers={"Content-Type": "application/json", "Accept": "application/json"},
            json={"short_description": issue, "comments": "Order " + str(order_id), "category": "inquiry"},
            timeout=10)
        if resp.status_code in (200, 201):
            inc = resp.json().get("result", {}).get("number")
    except Exception:
        inc = None
    session.sql(
        "INSERT INTO MCP_HOL.SUPPORT.TICKETS (TICKET_ID, ORDER_ID, ISSUE, SERVICENOW_INCIDENT, STATUS, CREATED_AT) "
        "VALUES (?, ?, ?, ?, 'OPEN', CURRENT_TIMESTAMP())",
        params=[tid, order_id, issue, inc]).collect()
    if inc:
        return "Opened ticket " + tid + " and ServiceNow incident " + inc + " for order " + str(order_id) + "."
    return "Opened ticket " + tid + " for order " + str(order_id) + " (ServiceNow not reachable yet - recorded in Snowflake)."
$$;
