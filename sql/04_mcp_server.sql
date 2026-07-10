-- The tool surface a Gemini agent (on Google Cloud) connects to over MCP.
-- One statement turns Snowflake objects into agent tools. This is the neobank
-- support agent's CUSTOMER-FACING surface: exactly four tools, nothing that can
-- read other customers, run arbitrary SQL, or move money. classify_intent is a
-- GENERIC *procedure* (a fine-tuned model is only reachable through the MCP
-- server via an owner's-rights procedure). search_help_articles is a Cortex
-- Search tool whose input schema is AUTO-GENERATED (query required;
-- columns/filter/limit optional) -- so it declares no input_schema block here.
CREATE OR REPLACE MCP SERVER MCP_HOL.AGENTS.MCP_HOL
FROM SPECIFICATION $$
tools:
  - name: "classify_intent"
    type: "GENERIC"
    identifier: "MCP_HOL.SUPPORT.CLASSIFY_INTENT_PROC"
    title: "Classify customer intent"
    description: "Classify a customer's message into exactly one of 77 neobank support intents (e.g. card_arrival, lost_or_stolen_card, declined_card_payment, transfer_timing, exchange_rate, verify_my_identity) using an in-account FINE-TUNED model. Returns one lowercase_with_underscores label. Call this FIRST to triage the message; its label is REQUIRED by file_ticket to route the case to the right team."
    config:
      type: "procedure"
      warehouse: "COCO_WH"
      input_schema:
        type: "object"
        properties:
          message: { type: "string", description: "The customer's message to classify" }
        required: ["message"]
  - name: "search_help_articles"
    type: "CORTEX_SEARCH_SERVICE_QUERY"
    identifier: "MCP_HOL.SUPPORT.SEARCH_HELP_ARTICLES"
    title: "Search help-centre articles"
    description: "Search the bank's help-centre knowledge base for a topic (card delivery times, lost/stolen card, declined payments, transfer timing, exchange rates, fees, identity verification, etc.) and return the most relevant articles. Each article has BODY plus attributes ARTICLE_ID, TITLE, CATEGORY; pass any of those names in the optional 'columns' arg to include them (only BODY is returned by default), and filter on CATEGORY via 'filter'."
  - name: "get_transaction_status"
    type: "GENERIC"
    identifier: "MCP_HOL.SUPPORT.GET_TRANSACTION_STATUS"
    title: "Look up a case or transaction"
    description: "Look up the status of a SINGLE support case or transaction by its reference id (e.g. CASE-10001). Returns the topic, current status, expected date, and channel detail."
    config:
      type: "function"
      warehouse: "COCO_WH"
      input_schema:
        type: "object"
        properties:
          ref_id: { type: "string", description: "The case/transaction reference, e.g. CASE-10001" }
        required: ["ref_id"]
  - name: "file_ticket"
    type: "GENERIC"
    identifier: "MCP_HOL.SUPPORT.FILE_TICKET"
    title: "Open a support incident"
    description: "File a support incident for the customer's case. Requires the intent label from classify_intent, which routes the incident to the right queue/priority (e.g. lost_or_stolen_card -> Cards & Fraud/P1, card_arrival -> Cards). Returns the incident number and routing."
    config:
      type: "procedure"
      warehouse: "COCO_WH"
      input_schema:
        type: "object"
        properties:
          ref_id: { type: "string", description: "The related case reference, e.g. CASE-10001" }
          issue: { type: "string", description: "Short description of the customer's problem" }
          intent: { type: "string", description: "The intent label from classify_intent (e.g. card_arrival). Used to route the incident." }
        required: ["ref_id", "issue", "intent"]
$$;

-- Re-grant the scoped role after CREATE OR REPLACE (a replace drops prior grants).
GRANT USAGE ON MCP SERVER MCP_HOL.AGENTS.MCP_HOL TO ROLE CUSTOMER_AGENT;
GRANT USAGE ON PROCEDURE MCP_HOL.SUPPORT.CLASSIFY_INTENT_PROC(VARCHAR) TO ROLE CUSTOMER_AGENT;

SHOW MCP SERVERS IN SCHEMA MCP_HOL.AGENTS;

-- ---------------------------------------------------------------------------
-- Extra layer of security: admit ONLY your agent's published egress IPs.
-- There is no ALTER MCP SERVER ... SET NETWORK_POLICY. The managed MCP server
-- authenticates through an OAuth security integration, so you enforce the IP
-- allow-list by attaching a network policy to THAT integration (integration-
-- and account-level policies gate the OAuth token request for MCP; user-level
-- policies are not evaluated for that traffic).
-- ---------------------------------------------------------------------------

-- 1. Allow only the agent's published egress IPs (Google Cloud / Vertex).
CREATE OR REPLACE NETWORK RULE MCP_HOL.AGENTS.MCP_CLIENT_INGRESS
  MODE = INGRESS
  TYPE = IPV4
  VALUE_LIST = ('<agent_egress_ip_1>', '<agent_egress_ip_2>');

CREATE NETWORK POLICY IF NOT EXISTS MCP_POLICY
  ALLOWED_NETWORK_RULE_LIST = ('MCP_HOL.AGENTS.MCP_CLIENT_INGRESS');

-- 2. Enforce it on the OAuth integration the MCP server uses.
ALTER SECURITY INTEGRATION MCP_OAUTH SET NETWORK_POLICY = MCP_POLICY;
