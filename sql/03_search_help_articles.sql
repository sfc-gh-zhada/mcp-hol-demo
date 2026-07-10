-- ============================================================
-- 03_search_help_articles.sql   (fintech pivot)
-- Knowledge base + Cortex Search service behind the search_help_articles tool.
-- The agent searches these neobank help articles to ground answers (e.g. how long
-- a new card takes, what to do about a declined payment) instead of guessing.
-- (Replaces the retail REVIEWS search + the unused SALES semantic view.)
-- ============================================================

CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.HELP_ARTICLES (
    ARTICLE_ID  VARCHAR,
    TITLE       VARCHAR,
    CATEGORY    VARCHAR,
    BODY        VARCHAR
);

INSERT INTO MCP_HOL.SUPPORT.HELP_ARTICLES (ARTICLE_ID, TITLE, CATEGORY, BODY) VALUES
('KB-001','How long does a new or replacement card take to arrive?','Cards',
 $$New and replacement debit cards are dispatched by standard post and typically arrive within 7 to 10 working days in the UK (up to 21 days internationally). You can track dispatch in the app under Cards. If it has been longer than 10 working days, we can cancel the missing card and reissue a new one at no charge.$$),
('KB-002','My card was lost or stolen','Cards & Fraud',
 $$If your card is lost or stolen, freeze it immediately in the app (Cards > Freeze) and report it so we can cancel it and issue a replacement. Freezing stops all new payments instantly. Any transactions you do not recognise can be disputed and are covered by our fraud protection.$$),
('KB-003','A top-up is not showing in my balance','Payments',
 $$Card and Apple Pay/Google Pay top-ups usually appear within a few minutes. If a top-up has not arrived after 2 hours, check that the payment was not declined by your other bank. Pending top-ups are automatically reversed within 3-5 working days if they do not complete.$$),
('KB-004','How long do bank transfers take?','Payments',
 $$Transfers between accounts in the same country are usually instant. International (SWIFT) transfers typically take 1 to 3 working days depending on the destination bank and currency. You can see the status of any transfer under Payments > Activity.$$),
('KB-005','Why was my card payment declined?','Cards',
 $$Common reasons a card payment is declined: insufficient balance, the card is frozen, a per-transaction or daily limit was reached, or the merchant is in a blocked category. Check Cards > Limits in the app. Contactless has a separate limit and may require a chip-and-PIN payment periodically.$$),
('KB-006','Understanding exchange rates and FX fees','FX',
 $$We use the interbank exchange rate with no markup on weekdays. A small fair-usage fee applies above your monthly free FX allowance, and a weekend surcharge applies Friday to Sunday because markets are closed. The exact rate is shown before you confirm any currency exchange.$$),
('KB-007','I see an extra charge or fee I do not recognise','Fees',
 $$Charges can come from ATM operator fees, out-of-allowance FX usage, or a merchant taking a deferred payment. Open the transaction in the app to see a full breakdown. If you still do not recognise it, you can raise a dispute and we will investigate within 10 working days.$$),
('KB-008','Verifying your identity','Account',
 $$To activate some features we need to verify your identity. Upload a valid photo ID and a selfie in the app under Profile > Verification. Verification usually completes within a few minutes but can take up to 24 hours if a manual review is needed.$$),
('KB-009','Activating your new card','Cards',
 $$Activate a new card by adding it to the app when it arrives (Cards > Activate) or by making your first chip-and-PIN payment. Your PIN can be viewed securely in the app. Cards cannot be used until activated.$$),
('KB-010','ATM withdrawals and limits','Cash',
 $$You can withdraw cash at any ATM showing the Visa/Mastercard logo. A monthly fee-free withdrawal allowance applies; beyond it a small percentage fee is charged. Some ATM operators add their own fee, which is shown on-screen before you confirm.$$),
('KB-011','Setting up and cancelling direct debits','Payments',
 $$Set up a direct debit by sharing your account and sort code with the biller. You can view and cancel active direct debits under Payments > Scheduled. Cancelling in the app stops future collections immediately; contact the biller to also cancel the agreement on their side.$$),
('KB-012','Disputing a transaction','Cards & Fraud',
 $$If you do not recognise a payment or a merchant charged you incorrectly, raise a dispute from the transaction details screen. Freeze your card first if you suspect fraud. Most disputes are resolved within 10 working days and a provisional refund may be issued while we investigate.$$),
('KB-013','Contactless payments are not working','Cards',
 $$Contactless can stop working if the per-transaction limit is exceeded, after several contactless payments in a row (a chip-and-PIN payment resets this), or if the card is frozen. Check Cards > Limits and make one chip-and-PIN payment to re-enable contactless.$$),
('KB-014','Changing your registered address or phone number','Account',
 $$Update your address or phone number under Profile > Personal details. A change of address may trigger a short security review before a new card can be sent. Keep your details current so card deliveries and security codes reach you.$$);

-- Cortex Search over the article body; attributes let the agent request/filter fields.
CREATE OR REPLACE CORTEX SEARCH SERVICE MCP_HOL.SUPPORT.SEARCH_HELP_ARTICLES
  ON BODY
  ATTRIBUTES ARTICLE_ID, TITLE, CATEGORY
  WAREHOUSE = COCO_WH
  TARGET_LAG = '1 hour'
  AS
    SELECT BODY, ARTICLE_ID, TITLE, CATEGORY
    FROM MCP_HOL.SUPPORT.HELP_ARTICLES;

GRANT USAGE ON CORTEX SEARCH SERVICE MCP_HOL.SUPPORT.SEARCH_HELP_ARTICLES TO ROLE CUSTOMER_AGENT;
