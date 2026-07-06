-- ============================================================
-- MCP_HOL.SUPPORT.ORDERS + GET_ORDER_STATUS tool
-- Backs the get_order_status MCP tool. 10 orders; ORD-10001 = the demo order.
--
-- IMPORTANT (named-argument contract): a GENERIC function MCP tool invokes the
-- UDF with the input_schema property name as a NAMED argument (e.g. ORDER_ID => ...).
-- So the UDF parameter MUST be named to match the MCP spec property (order_id).
-- Because ORDER_ID is also a column on ORDERS, we bind the parameter through a
-- CTE (input.oid) to avoid the param/column name collision.
-- ============================================================

CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.ORDERS (
    ORDER_ID        VARCHAR,
    CUSTOMER_EMAIL  VARCHAR,
    PRODUCT         VARCHAR,
    ORDER_DATE      DATE,
    STATUS          VARCHAR,
    CARRIER         VARCHAR,
    TRACKING_NO     VARCHAR,
    EST_DELIVERY    DATE
);

INSERT INTO MCP_HOL.SUPPORT.ORDERS
  (ORDER_ID, CUSTOMER_EMAIL, PRODUCT, ORDER_DATE, STATUS, CARRIER, TRACKING_NO, EST_DELIVERY)
VALUES
('ORD-10001','alex.customer@example.com','Summit Winter Jacket',     '2025-12-20','Delivered', 'UPS',  '1Z999AA10123456784',      '2026-01-05'),
('ORD-10002','maria.jones@example.com',  'Trail Runner Shoes',       '2026-01-15','Delivered', 'FedEx','794644790132',           '2026-01-22'),
('ORD-10003','ben.wilson@example.com',   'Alpine Down Vest',         '2026-02-01','In Transit','USPS', '9400111899223100001234', '2026-02-10'),
('ORD-10004','sarah.kim@example.com',    'Summit Winter Jacket',     '2026-02-05','Processing', NULL,   NULL,                     '2026-02-15'),
('ORD-10005','james.chen@example.com',   'Ridgeline Hiking Boots',   '2026-01-28','Delivered', 'UPS',  '1Z999AA10987654321',      '2026-02-04'),
('ORD-10006','lisa.patel@example.com',   'Cascade Rain Shell',       '2026-02-10','In Transit','FedEx','794644790256',           '2026-02-18'),
('ORD-10007','tom.nguyen@example.com',   'Basecamp Fleece Pullover', '2026-02-12','Processing', NULL,   NULL,                     '2026-02-22'),
('ORD-10008','emma.davis@example.com',   'Trail Runner Shoes',       '2026-01-05','Delivered', 'UPS',  '1Z999AA10555666777',      '2026-01-12'),
('ORD-10009','chris.martinez@example.com','Summit Winter Jacket',    '2026-02-15','In Transit','USPS', '9400111899223100005678', '2026-02-25'),
('ORD-10010','nina.zhao@example.com',    'Alpine Down Vest',         '2026-02-18','Processing', NULL,   NULL,                     '2026-02-28');

-- Owner's rights: CUSTOMER_AGENT can CALL it but cannot SELECT the ORDERS table.
CREATE OR REPLACE FUNCTION MCP_HOL.SUPPORT.GET_ORDER_STATUS(ORDER_ID VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
WITH input AS (SELECT ORDER_ID AS oid)
SELECT COALESCE(
  (SELECT 'Order ' || o.ORDER_ID || ' (' || o.PRODUCT || '): ' || o.STATUS ||
          CASE WHEN o.STATUS = 'Delivered'  THEN ' on ' || TO_VARCHAR(o.EST_DELIVERY, 'YYYY-MM-DD')
               WHEN o.STATUS = 'In Transit' THEN ', expected ' || TO_VARCHAR(o.EST_DELIVERY, 'YYYY-MM-DD')
               ELSE '' END ||
          CASE WHEN o.CARRIER IS NOT NULL THEN ' via ' || o.CARRIER || ', tracking ' || o.TRACKING_NO ELSE '' END ||
          '.'
   FROM MCP_HOL.SUPPORT.ORDERS o, input i
   WHERE o.ORDER_ID = i.oid),
  'No order found for ' || (SELECT oid FROM input) || '.')
$$;

GRANT USAGE ON FUNCTION MCP_HOL.SUPPORT.GET_ORDER_STATUS(VARCHAR) TO ROLE CUSTOMER_AGENT;
