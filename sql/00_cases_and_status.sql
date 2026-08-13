CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.CASES (
    REF_ID          VARCHAR,
    CUSTOMER_EMAIL  VARCHAR,
    TOPIC           VARCHAR,
    STATUS          VARCHAR,
    DETAIL          VARCHAR,
    OPENED_DATE     DATE,
    ETA             DATE
);

INSERT INTO MCP_HOL.SUPPORT.CASES
  (REF_ID, CUSTOMER_EMAIL, TOPIC, STATUS, DETAIL, OPENED_DATE, ETA)
VALUES
('CASE-10001','alex.customer@example.com','New debit card delivery','Dispatched','Sent via standard post','2026-02-01','2026-02-12'),
('CASE-10002','maria.jones@example.com','International transfer','In Progress','SWIFT transfer to EUR account','2026-02-08','2026-02-11'),
('CASE-10003','ben.wilson@example.com','Top-up not showing','Pending','Mobile-wallet top-up under review','2026-02-09','2026-02-10'),
('CASE-10004','sarah.kim@example.com','Replacement card (lost)','Dispatched','Expedited delivery','2026-02-06','2026-02-09'),
('CASE-10005','james.chen@example.com','Direct debit dispute','In Progress','Merchant contacted','2026-01-30','2026-02-13'),
('CASE-10006','lisa.patel@example.com','FX rate query','Completed','Rate explained, no action','2026-02-02','2026-02-02'),
('CASE-10007','tom.nguyen@example.com','Card payment declined','In Progress','Reviewing decline reason','2026-02-10','2026-02-12'),
('CASE-10008','emma.davis@example.com','Extra charge on statement','In Progress','Fee investigation','2026-02-05','2026-02-14'),
('CASE-10009','chris.martinez@example.com','New debit card delivery','In Progress','Card printing','2026-02-11','2026-02-20'),
('CASE-10010','nina.zhao@example.com','Identity verification','Pending','Awaiting document upload','2026-02-12','2026-02-15');

CREATE OR REPLACE FUNCTION MCP_HOL.SUPPORT.GET_TRANSACTION_STATUS(REF_ID VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
WITH input AS (SELECT REF_ID AS rid)
SELECT COALESCE(
  (SELECT 'Case ' || c.REF_ID || ' (' || c.TOPIC || '): ' || c.STATUS ||
          CASE WHEN c.STATUS IN ('Dispatched','In Progress','Pending')
               THEN ', expected by ' || TO_VARCHAR(c.ETA, 'YYYY-MM-DD') ELSE '' END ||
          CASE WHEN c.DETAIL IS NOT NULL THEN ' (' || c.DETAIL || ')' ELSE '' END || '.'
   FROM MCP_HOL.SUPPORT.CASES c, input i
   WHERE c.REF_ID = i.rid),
  'No case found for ' || (SELECT rid FROM input) || '.')
$$;

GRANT USAGE ON FUNCTION MCP_HOL.SUPPORT.GET_TRANSACTION_STATUS(VARCHAR) TO ROLE CUSTOMER_AGENT;