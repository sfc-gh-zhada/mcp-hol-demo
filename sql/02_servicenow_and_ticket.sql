-- Tickets table + sequence (local source of truth for the demo)
-- The ticket surface is a SELF-CONTAINED Snowflake stored procedure: it mints a
-- realistic ServiceNow-style incident number and logs it. There is NO external
-- connection, NO secret, and NO network egress -- so the customer-facing agent's
-- ACTION provably cannot reach anything outside the tools we declared on the MCP.
CREATE OR REPLACE SEQUENCE MCP_HOL.SUPPORT.TICKET_SEQ START = 1001 INCREMENT = 1;

CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.TICKETS (
  INCIDENT_NUMBER  STRING,       -- ServiceNow-style incident id, e.g. INC0001001
  ORDER_ID         STRING,
  ISSUE            STRING,
  STATUS           STRING,
  CREATED_AT       TIMESTAMP_NTZ
);

-- === file_ticket tool: self-contained, owner's rights ===
-- Owner's rights so CUSTOMER_AGENT can CALL it but cannot read TICKETS directly.
CREATE OR REPLACE PROCEDURE MCP_HOL.SUPPORT.FILE_TICKET(ORDER_ID STRING, ISSUE STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = 3.11
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run'
EXECUTE AS OWNER
AS
$$
def run(session, order_id, issue):
    seq = session.sql("SELECT MCP_HOL.SUPPORT.TICKET_SEQ.NEXTVAL").collect()[0][0]
    inc = "INC" + str(seq).zfill(7)
    session.sql(
        "INSERT INTO MCP_HOL.SUPPORT.TICKETS "
        "(INCIDENT_NUMBER, ORDER_ID, ISSUE, STATUS, CREATED_AT) "
        "VALUES (?, ?, ?, 'New', CURRENT_TIMESTAMP())",
        params=[inc, order_id, issue]).collect()
    return ("Created ServiceNow incident " + inc + " for order " + str(order_id)
            + " regarding: " + str(issue)
            + ". A support specialist has been assigned and will follow up shortly.")
$$;

-- Re-grant: CREATE OR REPLACE PROCEDURE drops existing grants.
GRANT USAGE ON PROCEDURE MCP_HOL.SUPPORT.FILE_TICKET(VARCHAR, VARCHAR) TO ROLE CUSTOMER_AGENT;

-- =====================================================================
-- OPTIONAL UPGRADE PATH (NOT run for the demo): point file_ticket at a
-- REAL ServiceNow instance via External Access. The agent surface and the
-- CUSTOMER_AGENT grants are identical -- only the procedure body changes,
-- so nothing about the governance story shifts. Uncomment + fill in a live
-- dev instance host, user, and password to enable.
-- =====================================================================
-- CREATE OR REPLACE NETWORK RULE MCP_HOL.SUPPORT.SERVICENOW_RULE
--   MODE = EGRESS TYPE = HOST_PORT VALUE_LIST = ('dev123456.service-now.com');
-- CREATE OR REPLACE SECRET MCP_HOL.SUPPORT.SERVICENOW_CRED
--   TYPE = PASSWORD USERNAME = 'svc_agent' PASSWORD = 'REPLACE_WITH_SERVICENOW_PASSWORD';
-- CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION SERVICENOW_MCP_HOL_INT
--   ALLOWED_NETWORK_RULES = (MCP_HOL.SUPPORT.SERVICENOW_RULE)
--   ALLOWED_AUTHENTICATION_SECRETS = (MCP_HOL.SUPPORT.SERVICENOW_CRED) ENABLED = TRUE;
-- Then CREATE OR REPLACE the procedure with:
--   EXTERNAL_ACCESS_INTEGRATIONS = (SERVICENOW_MCP_HOL_INT)
--   PACKAGES = ('snowflake-snowpark-python','requests')
--   SECRETS  = ('cred' = MCP_HOL.SUPPORT.SERVICENOW_CRED)
-- and POST to https://<host>/api/now/table/incident, reading resp.json()['result']['number']
-- as the incident number (fall back to the local INC id if unreachable).
