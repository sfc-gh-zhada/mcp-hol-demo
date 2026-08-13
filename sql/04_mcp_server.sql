CREATE OR REPLACE MCP SERVER MCP_HOL.AGENTS.MCP_HOL
FROM SPECIFICATION $$
tools:
  - name: "classify_intent"
    type: "GENERIC"
    identifier: "MCP_HOL.SUPPORT.CLASSIFY_INTENT_PROC"
    title: "Classify customer intent"
    description: "Classify a customer message into one of 77 neobank support intents. Call this first; its label is required by file_ticket."
    config:
      type: "procedure"
      warehouse: "COCO_WH"
      input_schema:
        type: "object"
        properties:
          message: { type: "string", description: "The raw customer message" }
        required: ["message"]
  - name: "search_help_articles"
    type: "CORTEX_SEARCH_SERVICE_QUERY"
    identifier: "MCP_HOL.SUPPORT.SEARCH_HELP_ARTICLES"
    title: "Search help-centre articles"
    description: "Search the synthetic help-centre knowledge base. BODY is returned by default; ARTICLE_ID, TITLE, and CATEGORY can be requested as columns."
  - name: "get_transaction_status"
    type: "GENERIC"
    identifier: "MCP_HOL.SUPPORT.GET_TRANSACTION_STATUS"
    title: "Look up a case or transaction"
    description: "Look up one synthetic support case by reference ID."
    config:
      type: "function"
      warehouse: "COCO_WH"
      input_schema:
        type: "object"
        properties:
          ref_id: { type: "string", description: "A case reference such as CASE-10001" }
        required: ["ref_id"]
  - name: "file_ticket"
    type: "GENERIC"
    identifier: "MCP_HOL.SUPPORT.FILE_TICKET"
    title: "Open a support incident"
    description: "Create and route a support incident. Requires the intent label returned by classify_intent."
    config:
      type: "procedure"
      warehouse: "COCO_WH"
      input_schema:
        type: "object"
        properties:
          ref_id: { type: "string", description: "The related case reference" }
          issue: { type: "string", description: "A short description of the issue" }
          intent: { type: "string", description: "The label returned by classify_intent" }
        required: ["ref_id", "issue", "intent"]
$$;

GRANT USAGE ON MCP SERVER MCP_HOL.AGENTS.MCP_HOL TO ROLE CUSTOMER_AGENT;
GRANT USAGE ON PROCEDURE MCP_HOL.SUPPORT.CLASSIFY_INTENT_PROC(VARCHAR) TO ROLE CUSTOMER_AGENT;
GRANT USAGE ON FUNCTION MCP_HOL.SUPPORT.GET_TRANSACTION_STATUS(VARCHAR) TO ROLE CUSTOMER_AGENT;
GRANT USAGE ON PROCEDURE MCP_HOL.SUPPORT.FILE_TICKET(VARCHAR, VARCHAR, VARCHAR) TO ROLE CUSTOMER_AGENT;
GRANT USAGE ON CORTEX SEARCH SERVICE MCP_HOL.SUPPORT.SEARCH_HELP_ARTICLES TO ROLE CUSTOMER_AGENT;

SHOW MCP SERVERS IN SCHEMA MCP_HOL.AGENTS;