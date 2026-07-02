-- The tool surface a Gemini agent (on Google Cloud) connects to over MCP.
-- One statement turns Snowflake objects into agent tools. read_only run_sql lets
-- the agent EXECUTE and return actual numbers (Cortex Analyst returns SQL, not rows).
-- Note what is NOT here: APPROVE_CASE. The agent can open a case; only a human approves.
CREATE OR REPLACE MCP SERVER MCP_HOL.AGENTS.MCP_HOL
FROM SPECIFICATION $$
tools:
  - name: "search_reviews"
    type: "CORTEX_SEARCH_SERVICE_QUERY"
    identifier: "MCP_HOL.SUPPORT.SEARCH_REVIEWS"
    title: "Search customer reviews"
    description: "Search customer reviews for a topic and return the most relevant reviews (shipping, sizing, zipper problems, etc.)."
  - name: "ask_sales_data"
    type: "CORTEX_ANALYST_MESSAGE"
    identifier: "MCP_HOL.SALES.SALES_SV"
    title: "Ask sales data"
    description: "Ask natural-language questions about sales: units, revenue, and refunds by product, region, or date. Returns the interpretation and the generated SQL."
  - name: "run_sql"
    type: "SYSTEM_EXECUTE_SQL"
    title: "Run read-only SQL"
    description: "Run a read-only SQL SELECT against Snowflake to quantify impact - e.g. count affected orders or sum refunds for a product. Discover tables and columns via INFORMATION_SCHEMA if needed. Use this to return the actual numbers."
    config:
      read_only: true
      warehouse: "COCO_WH"
  - name: "create_support_ticket"
    type: "GENERIC"
    identifier: "MCP_HOL.SUPPORT.CREATE_TICKET"
    title: "Open a refund-approval case"
    description: "Open a refund-approval CASE for an order. This does NOT issue a refund - it records the recommendation and routes it to a human for approval. Provide order_id, a short issue description, and the recommended refund amount."
    config:
      type: "procedure"
      warehouse: "COCO_WH"
      input_schema:
        type: "object"
        properties:
          order_id:
            type: "string"
            description: "The affected order id, e.g. ORD-10001"
          issue:
            type: "string"
            description: "Short description of the customer problem"
          recommended_refund:
            type: "number"
            description: "Recommended refund amount in dollars"
        required: ["order_id", "issue", "recommended_refund"]
$$;

SHOW MCP SERVERS IN SCHEMA MCP_HOL.AGENTS;
