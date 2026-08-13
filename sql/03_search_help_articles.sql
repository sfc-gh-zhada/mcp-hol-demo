CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.HELP_ARTICLES (
    ARTICLE_ID  VARCHAR,
    TITLE       VARCHAR,
    CATEGORY    VARCHAR,
    BODY        VARCHAR
);

INSERT INTO MCP_HOL.SUPPORT.HELP_ARTICLES (ARTICLE_ID, TITLE, CATEGORY, BODY) VALUES
('KB-001','How long does a new or replacement card take to arrive?','Cards',
 $$New and replacement debit cards are dispatched by standard post and typically arrive within 7 to 10 working days. International delivery can take up to 21 days. If it has been longer than 10 working days, support can cancel the missing card and reissue it at no charge.$$),
('KB-002','My card was lost or stolen','Cards & Fraud',
 $$If your card is lost or stolen, freeze it immediately in the app and report it so support can cancel it and issue a replacement. Freezing stops new payments. Transactions you do not recognize can be disputed.$$),
('KB-003','A top-up is not showing in my balance','Payments',
 $$Card and mobile-wallet top-ups usually appear within a few minutes. If a top-up has not arrived after two hours, confirm the payment was not declined by the other bank. Pending top-ups are automatically reversed within three to five working days if they do not complete.$$),
('KB-004','How long do bank transfers take?','Payments',
 $$Transfers between accounts in the same country are usually instant. International transfers typically take one to three working days depending on the destination bank and currency.$$),
('KB-005','Why was my card payment declined?','Cards',
 $$Common reasons a card payment is declined include insufficient balance, a frozen card, a transaction limit, or a blocked merchant category. Check card limits in the app before contacting support.$$),
('KB-006','Understanding exchange rates and FX fees','FX',
 $$The app shows the exchange rate and any applicable fee before confirmation. Additional fees can apply above the monthly allowance or when markets are closed.$$),
('KB-007','I see an extra charge or fee I do not recognize','Fees',
 $$Charges can come from ATM operator fees, out-of-allowance FX usage, or a deferred merchant payment. Open the transaction to see a full breakdown and raise a dispute if it remains unfamiliar.$$),
('KB-008','Verifying your identity','Account',
 $$Upload a valid photo ID and a selfie in the app. Verification usually completes within a few minutes but can take up to 24 hours when manual review is required.$$),
('KB-009','Activating your new card','Cards',
 $$Activate a new card in the app or by making the first chip-and-PIN payment. Cards cannot be used until activated.$$),
('KB-010','ATM withdrawals and limits','Cash',
 $$A monthly fee-free withdrawal allowance applies. Some ATM operators add their own fee, which is shown before confirmation.$$),
('KB-011','Setting up and cancelling direct debits','Payments',
 $$View and cancel active direct debits under scheduled payments. Cancelling in the app stops future collections; contact the biller to cancel the agreement on their side.$$),
('KB-012','Disputing a transaction','Cards & Fraud',
 $$If you do not recognize a payment or a merchant charged you incorrectly, raise a dispute from the transaction details screen. Freeze your card first if you suspect fraud.$$),
('KB-013','Contactless payments are not working','Cards',
 $$Contactless can stop working after a limit is reached or several contactless payments occur in a row. A chip-and-PIN payment can re-enable it.$$),
('KB-014','Changing your registered address or phone number','Account',
 $$Update your address or phone number under personal details. A change of address can trigger a short security review before a new card is sent.$$);

CREATE OR REPLACE CORTEX SEARCH SERVICE MCP_HOL.SUPPORT.SEARCH_HELP_ARTICLES
  ON BODY
  ATTRIBUTES ARTICLE_ID, TITLE, CATEGORY
  WAREHOUSE = COCO_WH
  TARGET_LAG = '1 hour'
  AS
    SELECT BODY, ARTICLE_ID, TITLE, CATEGORY
    FROM MCP_HOL.SUPPORT.HELP_ARTICLES;

GRANT USAGE ON CORTEX SEARCH SERVICE MCP_HOL.SUPPORT.SEARCH_HELP_ARTICLES TO ROLE CUSTOMER_AGENT;