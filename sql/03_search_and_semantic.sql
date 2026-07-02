-- Cortex Search service over customer reviews
CREATE OR REPLACE CORTEX SEARCH SERVICE MCP_HOL.SUPPORT.SEARCH_REVIEWS
  ON REVIEW_TEXT
  ATTRIBUTES PRODUCT, RATING, ORDER_ID, REVIEW_DATE
  WAREHOUSE = COCO_WH
  TARGET_LAG = '1 hour'
  AS
    SELECT REVIEW_TEXT, PRODUCT, RATING, ORDER_ID, REVIEW_DATE
    FROM MCP_HOL.SUPPORT.REVIEWS;

-- Semantic view for Cortex Analyst (ask_sales_data)
CREATE OR REPLACE SEMANTIC VIEW MCP_HOL.SALES.SALES_SV
  TABLES (
    sales AS MCP_HOL.SALES.SALES_FACT PRIMARY KEY (ORDER_ID)
  )
  DIMENSIONS (
    sales.product   AS PRODUCT,
    sales.region    AS REGION,
    sales.order_date AS ORDER_DATE
  )
  METRICS (
    sales.total_units   AS SUM(UNITS),
    sales.total_revenue AS SUM(REVENUE),
    sales.total_refunds AS SUM(REFUND_AMT),
    sales.order_count   AS COUNT(ORDER_ID)
  )
  COMMENT = 'Sales facts by product/region/date for the MCP HOL demo';
