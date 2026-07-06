-- ============================================================
-- 06_finetune_intent.sql   (order-dependent; run AFTER 01-05)
-- A small, cheap fine-tuned intent classifier for the webinar demo.
--
--   Base model : llama3.1-8b  (verified callable; NOT on the May/July 2026
--                Cortex model-deprecation lists -> durable base)
--   Domain     : retail-apparel customer-support messages (matches SUPPORT.REVIEWS)
--   Produces   : MCP_HOL.SUPPORT.SUPPORT_INTENT_8B  (fine-tuned model)
--                MCP_HOL.SUPPORT.CLASSIFY_INTENT(message)  (the tool wrapper UDF)
--
-- WHY a fine-tune here: it is the one MCP tool whose DECISION BOUNDARY you own.
-- A frontier model can be prompted; only a fine-tune is trained on YOUR labels.
--
-- IMPORTANT (best practice): SNOWFLAKE.CORTEX.FINETUNE('CREATE') is asynchronous
-- and long-running. Do NOT place it in the attendee Run-All notebook path (a
-- long/failed cell halts Run All). Run it ONCE here, poll DESCRIBE to SUCCESS,
-- then the notebook only CALLS the pre-provisioned model.
--
-- GC WARNING: fine-tune jobs are garbage-collected over ~weeks (this is why the
-- prior BANK_INTENT_8B went "unavailable"). Create this model CLOSE to the
-- webinar and re-verify callability the day before.
-- ============================================================

-- ------------------------------------------------------------
-- Step 1  Labeled data: TRAIN (~20/intent) / VAL (~5/intent) / PROBE (~4/intent)
-- Six clean, learnable intents for the apparel-support desk.
-- Messages use $$...$$ dollar-quoting so apostrophes need no escaping.
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.INTENT_TRAIN (MESSAGE STRING, INTENT STRING);
INSERT INTO MCP_HOL.SUPPORT.INTENT_TRAIN (MESSAGE, INTENT) VALUES
($$Where is my order? I placed it four days ago and haven't heard anything.$$, 'ORDER_STATUS'),
($$Can you tell me if my jacket has shipped yet?$$, 'ORDER_STATUS'),
($$I need a tracking number for order ORD-20101.$$, 'ORDER_STATUS'),
($$Has my order left the warehouse? I want to know when it will arrive.$$, 'ORDER_STATUS'),
($$What's the status of my recent purchase?$$, 'ORDER_STATUS'),
($$I ordered two items last week and want an update on delivery.$$, 'ORDER_STATUS'),
($$Is my package on its way? No tracking email came through.$$, 'ORDER_STATUS'),
($$Could you check whether my order is being processed or already shipped?$$, 'ORDER_STATUS'),
($$When will my order be dispatched?$$, 'ORDER_STATUS'),
($$I haven't received a shipping confirmation. Can you confirm the order went through?$$, 'ORDER_STATUS'),
($$Please give me an update on where my parcel currently is.$$, 'ORDER_STATUS'),
($$Which carrier is delivering my order and when should I expect it?$$, 'ORDER_STATUS'),
($$My order still says processing — is that normal after three days?$$, 'ORDER_STATUS'),
($$Can I get an ETA on my delivery?$$, 'ORDER_STATUS'),
($$I want to confirm my order was received and is on schedule.$$, 'ORDER_STATUS'),
($$Any update on my shipment? The status hasn't changed since Monday.$$, 'ORDER_STATUS'),
($$How do I track the jacket I bought?$$, 'ORDER_STATUS'),
($$Is there a way to see the delivery date for my order?$$, 'ORDER_STATUS'),
($$I'd like to know if my order shipped today.$$, 'ORDER_STATUS'),
($$Checking in on my order — has it been handed to the courier yet?$$, 'ORDER_STATUS'),
($$My order is a week late and still hasn't arrived.$$, 'SHIPPING_DELAY'),
($$The tracking hasn't updated in five days — is my package lost?$$, 'SHIPPING_DELAY'),
($$It was supposed to arrive Tuesday and it's now Friday with no jacket.$$, 'SHIPPING_DELAY'),
($$Why is my delivery taking so much longer than the estimate?$$, 'SHIPPING_DELAY'),
($$My parcel has been stuck in transit for over a week.$$, 'SHIPPING_DELAY'),
($$The promised two-day shipping is now on day six. Where is it?$$, 'SHIPPING_DELAY'),
($$My order is significantly delayed and I need it for a trip.$$, 'SHIPPING_DELAY'),
($$Tracking says delayed but gives no new date. This is frustrating.$$, 'SHIPPING_DELAY'),
($$It's been two weeks and my package still hasn't shown up.$$, 'SHIPPING_DELAY'),
($$The estimated delivery keeps getting pushed back further.$$, 'SHIPPING_DELAY'),
($$My shipment appears stuck at a facility and isn't moving.$$, 'SHIPPING_DELAY'),
($$I paid for expedited shipping but it's later than standard would have been.$$, 'SHIPPING_DELAY'),
($$Still waiting on a package that was due last week.$$, 'SHIPPING_DELAY'),
($$The courier missed the delivery window and now there's no update.$$, 'SHIPPING_DELAY'),
($$My order has been delayed twice with no explanation.$$, 'SHIPPING_DELAY'),
($$Nothing has arrived and the tracking is frozen.$$, 'SHIPPING_DELAY'),
($$Delivery is way past the date you promised at checkout.$$, 'SHIPPING_DELAY'),
($$My package seems to be lost in transit — it hasn't moved in days.$$, 'SHIPPING_DELAY'),
($$Why has my order not arrived when it shipped ten days ago?$$, 'SHIPPING_DELAY'),
($$I'm still waiting — the delay is unacceptable for the price I paid.$$, 'SHIPPING_DELAY'),
($$The zipper on my jacket broke on the very first use.$$, 'DEFECTIVE_ITEM'),
($$My jacket arrived with a torn seam along the shoulder.$$, 'DEFECTIVE_ITEM'),
($$The zipper gets stuck every time and won't close.$$, 'DEFECTIVE_ITEM'),
($$There's a hole in the lining of the jacket I received.$$, 'DEFECTIVE_ITEM'),
($$The zip pull snapped off in my hand after two days.$$, 'DEFECTIVE_ITEM'),
($$My item is clearly defective — the stitching is coming apart.$$, 'DEFECTIVE_ITEM'),
($$The waterproof coating is peeling off already.$$, 'DEFECTIVE_ITEM'),
($$The zipper separated at the bottom and the jacket won't stay closed.$$, 'DEFECTIVE_ITEM'),
($$One of the buttons fell off immediately and the fabric is fraying.$$, 'DEFECTIVE_ITEM'),
($$The jacket has a manufacturing defect — the sleeve is sewn crooked.$$, 'DEFECTIVE_ITEM'),
($$My zipper jammed halfway and now it's completely stuck.$$, 'DEFECTIVE_ITEM'),
($$The product came damaged, with a rip near the pocket.$$, 'DEFECTIVE_ITEM'),
($$The zip broke mid-hike and left me freezing.$$, 'DEFECTIVE_ITEM'),
($$There's a defect in the material — it's already pilling badly.$$, 'DEFECTIVE_ITEM'),
($$The jacket's snaps don't hold and the zipper is faulty.$$, 'DEFECTIVE_ITEM'),
($$Received a jacket with a broken zipper slider straight out of the box.$$, 'DEFECTIVE_ITEM'),
($$The seams are unraveling after one wash — poor quality.$$, 'DEFECTIVE_ITEM'),
($$My jacket's zipper teeth are misaligned and it won't zip.$$, 'DEFECTIVE_ITEM'),
($$The item is faulty; the zipper mechanism failed completely.$$, 'DEFECTIVE_ITEM'),
($$A big tear appeared in the fabric after light use — clearly defective.$$, 'DEFECTIVE_ITEM'),
($$I'd like to return this jacket and get a refund.$$, 'RETURN_REFUND'),
($$How do I send this back for my money back?$$, 'RETURN_REFUND'),
($$I want a full refund for my order.$$, 'RETURN_REFUND'),
($$Please process a refund — this isn't what I wanted.$$, 'RETURN_REFUND'),
($$Can I return the item? I've changed my mind.$$, 'RETURN_REFUND'),
($$I need to initiate a return and refund for order ORD-20155.$$, 'RETURN_REFUND'),
($$This didn't work out; I'd like my money back.$$, 'RETURN_REFUND'),
($$What's your return policy? I want to send this back.$$, 'RETURN_REFUND'),
($$I'm requesting a refund for the jacket I purchased.$$, 'RETURN_REFUND'),
($$Please refund me — I no longer need the item.$$, 'RETURN_REFUND'),
($$I'd like to return it, it's unopened and unused.$$, 'RETURN_REFUND'),
($$Can you refund my card for this order?$$, 'RETURN_REFUND'),
($$I want to return this and be reimbursed in full.$$, 'RETURN_REFUND'),
($$How long does a refund take after I return the jacket?$$, 'RETURN_REFUND'),
($$Requesting a return label so I can get a refund.$$, 'RETURN_REFUND'),
($$I decided against keeping it — please arrange a refund.$$, 'RETURN_REFUND'),
($$Return request: I want my money back for this purchase.$$, 'RETURN_REFUND'),
($$Can I get a refund instead of store credit?$$, 'RETURN_REFUND'),
($$I'd like to cancel and refund this order if possible.$$, 'RETURN_REFUND'),
($$Please help me return this jacket for a refund.$$, 'RETURN_REFUND'),
($$The jacket is too small — can I exchange it for a larger size?$$, 'SIZING_EXCHANGE'),
($$I ordered a medium but it fits like an extra-small.$$, 'SIZING_EXCHANGE'),
($$Can I swap this for the next size up?$$, 'SIZING_EXCHANGE'),
($$The fit is too big; I'd like to exchange for a smaller size.$$, 'SIZING_EXCHANGE'),
($$Wrong size arrived — I need to exchange it.$$, 'SIZING_EXCHANGE'),
($$This runs large. How do I exchange for a size down?$$, 'SIZING_EXCHANGE'),
($$The sleeves are too short — can I get a different size?$$, 'SIZING_EXCHANGE'),
($$I need to exchange my large for an extra-large.$$, 'SIZING_EXCHANGE'),
($$It doesn't fit. Can I trade it for another size?$$, 'SIZING_EXCHANGE'),
($$The jacket is snug in the shoulders; I want a bigger size.$$, 'SIZING_EXCHANGE'),
($$Please exchange this for a medium instead of a small.$$, 'SIZING_EXCHANGE'),
($$Sizing is off — can I swap for the correct fit?$$, 'SIZING_EXCHANGE'),
($$I'd like to exchange this item for a different size.$$, 'SIZING_EXCHANGE'),
($$The size chart was misleading; I need a larger one.$$, 'SIZING_EXCHANGE'),
($$Can I do a size exchange without paying return shipping?$$, 'SIZING_EXCHANGE'),
($$This is way too big on me — exchange for small please.$$, 'SIZING_EXCHANGE'),
($$Need to change the size on my order; it's too tight.$$, 'SIZING_EXCHANGE'),
($$The fit is wrong. What's the process to exchange sizes?$$, 'SIZING_EXCHANGE'),
($$I want the same jacket but one size larger.$$, 'SIZING_EXCHANGE'),
($$Exchange request: the medium is too long, I need a small.$$, 'SIZING_EXCHANGE'),
($$Just wanted to say I love this jacket — great quality!$$, 'GENERAL_FEEDBACK'),
($$Fantastic product and fast service. Thank you!$$, 'GENERAL_FEEDBACK'),
($$The jacket is warm and looks amazing. Very happy.$$, 'GENERAL_FEEDBACK'),
($$Excellent experience overall, will buy again.$$, 'GENERAL_FEEDBACK'),
($$Really impressed with the craftsmanship of this coat.$$, 'GENERAL_FEEDBACK'),
($$Great customer service, keep it up!$$, 'GENERAL_FEEDBACK'),
($$This is the best winter jacket I've owned. Highly recommend.$$, 'GENERAL_FEEDBACK'),
($$Love the design and the fit is perfect. Five stars.$$, 'GENERAL_FEEDBACK'),
($$Just leaving some positive feedback — wonderful purchase.$$, 'GENERAL_FEEDBACK'),
($$The quality exceeded my expectations. Thanks!$$, 'GENERAL_FEEDBACK'),
($$Very comfortable and stylish. I'm delighted.$$, 'GENERAL_FEEDBACK'),
($$Superb jacket, worth every penny.$$, 'GENERAL_FEEDBACK'),
($$Wanted to compliment your team on a smooth experience.$$, 'GENERAL_FEEDBACK'),
($$Amazing warmth and great looks — couldn't be happier.$$, 'GENERAL_FEEDBACK'),
($$Really nice product, my whole family loves theirs.$$, 'GENERAL_FEEDBACK'),
($$Top-notch quality and quick delivery. Well done.$$, 'GENERAL_FEEDBACK'),
($$This jacket is perfect for the cold. Great job!$$, 'GENERAL_FEEDBACK'),
($$I appreciate the excellent packaging and product quality.$$, 'GENERAL_FEEDBACK'),
($$Best purchase I've made this winter. Thank you so much!$$, 'GENERAL_FEEDBACK'),
($$Just wanted to share how much I enjoy this jacket.$$, 'GENERAL_FEEDBACK');

CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.INTENT_VAL (MESSAGE STRING, INTENT STRING);
INSERT INTO MCP_HOL.SUPPORT.INTENT_VAL (MESSAGE, INTENT) VALUES
($$Any news on my order? I'd love a tracking update.$$, 'ORDER_STATUS'),
($$Can you confirm my purchase shipped out?$$, 'ORDER_STATUS'),
($$I want to know the current status of my delivery.$$, 'ORDER_STATUS'),
($$Where does my package stand right now?$$, 'ORDER_STATUS'),
($$Has my order been sent yet?$$, 'ORDER_STATUS'),
($$My delivery is overdue by several days.$$, 'SHIPPING_DELAY'),
($$The package hasn't budged in transit for a week.$$, 'SHIPPING_DELAY'),
($$Shipping is taking far longer than promised.$$, 'SHIPPING_DELAY'),
($$Still no jacket and it's well past the delivery date.$$, 'SHIPPING_DELAY'),
($$My order is delayed again with no clear ETA.$$, 'SHIPPING_DELAY'),
($$The zipper failed the first day I wore it.$$, 'DEFECTIVE_ITEM'),
($$My jacket showed up with a ripped pocket.$$, 'DEFECTIVE_ITEM'),
($$The stitching came undone after minimal use.$$, 'DEFECTIVE_ITEM'),
($$The zipper slider broke and won't move at all.$$, 'DEFECTIVE_ITEM'),
($$The fabric tore easily — clearly a defect.$$, 'DEFECTIVE_ITEM'),
($$I'd like to return this and get reimbursed.$$, 'RETURN_REFUND'),
($$Please refund my order, it's not for me.$$, 'RETURN_REFUND'),
($$How do I get my money back for this jacket?$$, 'RETURN_REFUND'),
($$Requesting a refund and a return label.$$, 'RETURN_REFUND'),
($$I want to send this back for a full refund.$$, 'RETURN_REFUND'),
($$Too tight in the chest — need a larger size.$$, 'SIZING_EXCHANGE'),
($$Can I exchange this medium for a small?$$, 'SIZING_EXCHANGE'),
($$The fit is off; I'd like a size up.$$, 'SIZING_EXCHANGE'),
($$Wrong size; please help me exchange it.$$, 'SIZING_EXCHANGE'),
($$I need to swap for a different size.$$, 'SIZING_EXCHANGE'),
($$Love the jacket, superb quality!$$, 'GENERAL_FEEDBACK'),
($$Great service and a wonderful product.$$, 'GENERAL_FEEDBACK'),
($$So happy with this purchase, thank you.$$, 'GENERAL_FEEDBACK'),
($$Excellent coat, highly recommend it.$$, 'GENERAL_FEEDBACK'),
($$Really pleased with the whole experience.$$, 'GENERAL_FEEDBACK');

CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.INTENT_PROBE (MESSAGE STRING, INTENT STRING);
INSERT INTO MCP_HOL.SUPPORT.INTENT_PROBE (MESSAGE, INTENT) VALUES
($$Could you update me on when my order ships?$$, 'ORDER_STATUS'),
($$I haven't gotten a tracking link yet — what's my order status?$$, 'ORDER_STATUS'),
($$Is my package out for delivery?$$, 'ORDER_STATUS'),
($$Checking on the progress of my order.$$, 'ORDER_STATUS'),
($$My order is late and tracking is stuck.$$, 'SHIPPING_DELAY'),
($$It's been ten days and nothing has arrived.$$, 'SHIPPING_DELAY'),
($$The shipment is way behind the promised date.$$, 'SHIPPING_DELAY'),
($$Why is my delivery delayed with no update?$$, 'SHIPPING_DELAY'),
($$The zipper broke after one wear.$$, 'DEFECTIVE_ITEM'),
($$My jacket arrived with a torn sleeve.$$, 'DEFECTIVE_ITEM'),
($$The zip is jammed and won't close at all.$$, 'DEFECTIVE_ITEM'),
($$There's a defect — the seam split open.$$, 'DEFECTIVE_ITEM'),
($$I want to return this jacket for a refund.$$, 'RETURN_REFUND'),
($$Please process my money back for this order.$$, 'RETURN_REFUND'),
($$How do I return it and get reimbursed?$$, 'RETURN_REFUND'),
($$Requesting a full refund, please.$$, 'RETURN_REFUND'),
($$The jacket's too small; can I exchange for a bigger size?$$, 'SIZING_EXCHANGE'),
($$Need to swap this for a size up.$$, 'SIZING_EXCHANGE'),
($$It runs large — exchange for a smaller one?$$, 'SIZING_EXCHANGE'),
($$Wrong fit, I'd like a different size.$$, 'SIZING_EXCHANGE'),
($$Absolutely love this jacket, great quality!$$, 'GENERAL_FEEDBACK'),
($$Fantastic product and speedy shipping.$$, 'GENERAL_FEEDBACK'),
($$Very happy customer — well done.$$, 'GENERAL_FEEDBACK'),
($$The coat is perfect, highly recommend.$$, 'GENERAL_FEEDBACK'),
-- Messy real-world inbound (terse, typos, slang) — a realistic support queue has these.
-- This is where a fine-tune's learned label discipline separates from base zero-shot.
($$zippr busted lol$$, 'DEFECTIVE_ITEM'),
($$still not here?? ordered 3 wks ago$$, 'SHIPPING_DELAY'),
($$need it bigger$$, 'SIZING_EXCHANGE'),
($$money back pls$$, 'RETURN_REFUND'),
($$tracking???$$, 'ORDER_STATUS'),
($$10/10 coat$$, 'GENERAL_FEEDBACK'),
($$it rips at the seam$$, 'DEFECTIVE_ITEM'),
($$wrong size ugh$$, 'SIZING_EXCHANGE'),
($$where package$$, 'ORDER_STATUS'),
($$shipping wayyy late$$, 'SHIPPING_DELAY'),
($$want refund asap$$, 'RETURN_REFUND'),
($$fits perfect love it$$, 'GENERAL_FEEDBACK');

-- ------------------------------------------------------------
-- Step 2  Kick off the fine-tune (ASYNC -> returns a job id).
-- The prompt string is IDENTICAL to the one CLASSIFY_INTENT uses at inference,
-- so train-time and serve-time prompts match. completion = the bare label.
-- ------------------------------------------------------------
-- Idempotency: drop any prior model of this name so re-runs succeed cleanly.
DROP MODEL IF EXISTS MCP_HOL.SUPPORT.SUPPORT_INTENT_8B;

SELECT SNOWFLAKE.CORTEX.FINETUNE(
  'CREATE',
  'MCP_HOL.SUPPORT.SUPPORT_INTENT_8B',
  'llama3.1-8b',
  $$SELECT 'Classify the customer support message into exactly one label from this list: ORDER_STATUS, SHIPPING_DELAY, DEFECTIVE_ITEM, RETURN_REFUND, SIZING_EXCHANGE, GENERAL_FEEDBACK. Reply with only the label and nothing else. Message: ' || MESSAGE || ' Label:' AS prompt, INTENT AS completion FROM MCP_HOL.SUPPORT.INTENT_TRAIN$$,
  $$SELECT 'Classify the customer support message into exactly one label from this list: ORDER_STATUS, SHIPPING_DELAY, DEFECTIVE_ITEM, RETURN_REFUND, SIZING_EXCHANGE, GENERAL_FEEDBACK. Reply with only the label and nothing else. Message: ' || MESSAGE || ' Label:' AS prompt, INTENT AS completion FROM MCP_HOL.SUPPORT.INTENT_VAL$$
);
-- Poll to completion (replace <job_id> with the id returned above):
--   SELECT SNOWFLAKE.CORTEX.FINETUNE('DESCRIBE', '<job_id>');
-- Wait for "status": "SUCCESS" before the model is callable.

-- ------------------------------------------------------------
-- Step 3  The tool wrapper UDF the MCP GENERIC tool points at.
-- Same prompt as training; TRIM/UPPER normalizes to a clean label.
-- (DDL succeeds even before training finishes; calls work once model is SUCCESS.)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION MCP_HOL.SUPPORT.CLASSIFY_INTENT(message STRING)
RETURNS STRING
AS
$$
    UPPER(TRIM(SNOWFLAKE.CORTEX.COMPLETE(
        'MCP_HOL.SUPPORT.SUPPORT_INTENT_8B',
        'Classify the customer support message into exactly one label from this list: ORDER_STATUS, SHIPPING_DELAY, DEFECTIVE_ITEM, RETURN_REFUND, SIZING_EXCHANGE, GENERAL_FEEDBACK. Reply with only the label and nothing else. Message: ' || message || ' Label:'
    )))
$$;

-- ------------------------------------------------------------
-- Step 4  Verify + score: fine-tuned vs base llama3.1-8b zero-shot on the probe.
-- Capture FT_ACCURACY for the talk track ("fine-tuned beats base zero-shot").
-- ------------------------------------------------------------
WITH scored AS (
  SELECT
    INTENT AS actual,
    MCP_HOL.SUPPORT.CLASSIFY_INTENT(MESSAGE) AS ft_pred,
    UPPER(TRIM(SNOWFLAKE.CORTEX.COMPLETE(
      'llama3.1-8b',
      'Classify the customer support message into exactly one label from this list: ORDER_STATUS, SHIPPING_DELAY, DEFECTIVE_ITEM, RETURN_REFUND, SIZING_EXCHANGE, GENERAL_FEEDBACK. Reply with only the label and nothing else. Message: ' || MESSAGE || ' Label:'
    ))) AS base_pred
  FROM MCP_HOL.SUPPORT.INTENT_PROBE
)
SELECT
  COUNT(*)                                                        AS probe_rows,
  ROUND(AVG(IFF(ft_pred   = actual, 1, 0)) * 100, 1)              AS ft_accuracy_pct,
  ROUND(AVG(IFF(base_pred = actual, 1, 0)) * 100, 1)             AS base_zeroshot_accuracy_pct
FROM scored;

-- ------------------------------------------------------------
-- Pre-webinar callability check (RUN THE DAY BEFORE).
-- Fine-tune jobs/models are garbage-collected over ~weeks; if this errors with
-- "model ... is unavailable", re-run this whole script to recreate the model.
-- ------------------------------------------------------------
--   SELECT MCP_HOL.SUPPORT.CLASSIFY_INTENT('The zipper broke on day one');  -- expect DEFECTIVE_ITEM
