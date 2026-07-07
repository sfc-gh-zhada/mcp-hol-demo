-- The tool surface a Gemini agent (on Google Cloud) connects to over MCP.
-- One statement turns Snowflake objects into agent tools. This is the CUSTOMER-
-- FACING surface: exactly four tools, nothing that can read other customers,
-- run arbitrary SQL, or issue refunds. classify_intent is a GENERIC *procedure*
-- (a fine-tuned model is only reachable through the MCP server via an owner's-
-- rights procedure). search_reviews is a Cortex Search tool whose input schema
-- is AUTO-GENERATED (query required; columns/filter/limit optional) -- so it
-- declares no input_schema block here.
CREATE OR REPLACE MCP SERVER MCP_HOL.AGENTS.MCP_HOL
FROM SPECIFICATION $$
tools:
  - name: "classify_intent"
    type: "GENERIC"
    identifier: "MCP_HOL.SUPPORT.CLASSIFY_INTENT_PROC"
    title: "Classify customer intent"
    description: "Classify a customer's message into exactly one support intent label (ORDER_STATUS, SHIPPING_DELAY, DEFECTIVE_ITEM, RETURN_REFUND, SIZING_EXCHANGE, GENERAL_FEEDBACK) using a fine-tuned model. Call this FIRST to triage the customer's message; its label is required to file a ticket."
    config:
      type: "procedure"
      warehouse: "COCO_WH"
      input_schema:
        type: "object"
        properties:
          message: { type: "string", description: "The customer's message to classify" }
        required: ["message"]
  - name: "search_reviews"
    type: "CORTEX_SEARCH_SERVICE_QUERY"
    identifier: "MCP_HOL.SUPPORT.SEARCH_REVIEWS"
    title: "Search customer reviews"
    description: "Search customer product reviews for a topic (zipper problems, sizing, shipping, warmth, etc.) and return the most relevant matching reviews."
  - name: "get_order_status"
    type: "GENERIC"
    identifier: "MCP_HOL.SUPPORT.GET_ORDER_STATUS"
    title: "Look up order status"
    description: "Look up the status and shipment details of a SINGLE order by its order id. Returns the current status, carrier, tracking number, and delivery date."
    config:
      type: "function"
      warehouse: "COCO_WH"
      input_schema:
        type: "object"
        properties:
          order_id: { type: "string", description: "The customer's order id, e.g. ORD-10001" }
        required: ["order_id"]
  - name: "file_ticket"
    type: "GENERIC"
    identifier: "MCP_HOL.SUPPORT.FILE_TICKET"
    title: "Open a ServiceNow incident"
    description: "File a ServiceNow incident for the customer's order. Requires the intent label from classify_intent, which routes the incident to the right queue/priority. Returns the incident number and routing."
    config:
      type: "procedure"
      warehouse: "COCO_WH"
      input_schema:
        type: "object"
        properties:
          order_id: { type: "string", description: "The affected order id, e.g. ORD-10001" }
          issue: { type: "string", description: "Short description of the customer's problem" }
          intent: { type: "string", description: "The intent label from classify_intent (e.g. DEFECTIVE_ITEM). Used to route the incident." }
        required: ["order_id", "issue", "intent"]
$$;

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
