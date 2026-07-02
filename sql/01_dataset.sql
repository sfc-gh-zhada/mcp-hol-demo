-- ============================================================
-- MCP_HOL Demo Dataset: Customer Reviews + Sales
-- Populates SUPPORT.REVIEWS (62 rows) and SALES.SALES_FACT (65 rows)
-- Summit Winter Jacket: 44 reviews (38 zipper complaints), 320 units, $9,000 refunds
-- ============================================================


-- ============================================================
-- Table 1: MCP_HOL.SUPPORT.REVIEWS
-- ============================================================
CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.REVIEWS (
    REVIEW_ID   INT,
    ORDER_ID    STRING,
    PRODUCT     STRING,
    RATING      INT,
    REVIEW_TEXT STRING,
    REVIEW_DATE DATE
);

INSERT INTO MCP_HOL.SUPPORT.REVIEWS (REVIEW_ID, ORDER_ID, PRODUCT, RATING, REVIEW_TEXT, REVIEW_DATE)
VALUES
-- Summit Winter Jacket – zipper complaints (ratings 1–2, rows 1–38)
(1,  'ORD-10001', 'Summit Winter Jacket', 1, 'The zipper broke on my very first outing. Completely unwearable and I had to return it.',                                        DATEADD(DAY, -3,  CURRENT_DATE)),
(2,  'ORD-10002', 'Summit Winter Jacket', 1, 'Zipper got stuck after one wash and now it won''t zip at all. Total manufacturing defect.',                                        DATEADD(DAY, -5,  CURRENT_DATE)),
(3,  'ORD-10003', 'Summit Winter Jacket', 2, 'Beautiful jacket ruined by a broken zipper. The zip just split open on a cold morning hike.',                                     DATEADD(DAY, -6,  CURRENT_DATE)),
(4,  'ORD-10004', 'Summit Winter Jacket', 2, 'The jacket looks premium but the zipper is a disaster. It gets stuck every single time I try to close it.',                       DATEADD(DAY, -8,  CURRENT_DATE)),
(5,  'ORD-10005', 'Summit Winter Jacket', 1, 'Zipper snapped off within a week. Contacted support and still waiting for a resolution.',                                          DATEADD(DAY, -10, CURRENT_DATE)),
(6,  'ORD-10006', 'Summit Winter Jacket', 2, 'The zip won''t close past the midpoint. Feels like a manufacturing defect. Very disappointed.',                                    DATEADD(DAY, -11, CURRENT_DATE)),
(7,  'ORD-10007', 'Summit Winter Jacket', 1, 'Third Summit jacket I''ve owned and the first with a zipper issue. The zip broke after just two uses.',                            DATEADD(DAY, -13, CURRENT_DATE)),
(8,  'ORD-10008', 'Summit Winter Jacket', 1, 'Zip broke in the cold after the very first use. Seems like a widespread defect based on other reviews here.',                      DATEADD(DAY, -15, CURRENT_DATE)),
(9,  'ORD-10009', 'Summit Winter Jacket', 1, 'Bought as a gift and the zipper broke the first time my son wore it. Extremely embarrassing.',                                    DATEADD(DAY, -16, CURRENT_DATE)),
(10, 'ORD-10010', 'Summit Winter Jacket', 2, 'The zipper stuck on day two and I can barely get the jacket on now. Not worth the price.',                                        DATEADD(DAY, -18, CURRENT_DATE)),
(11, 'ORD-10011', 'Summit Winter Jacket', 1, 'Do not buy this jacket. The zipper failed completely on the first cold day I wore it outdoors.',                                  DATEADD(DAY, -20, CURRENT_DATE)),
(12, 'ORD-10012', 'Summit Winter Jacket', 2, 'Great design but the zip is totally broken after two weeks of normal use. Clearly a bad batch.',                                  DATEADD(DAY, -21, CURRENT_DATE)),
(13, 'ORD-10013', 'Summit Winter Jacket', 1, 'Zipper came apart at the bottom seam. The jacket is otherwise fine but completely unusable.',                                     DATEADD(DAY, -23, CURRENT_DATE)),
(14, 'ORD-10014', 'Summit Winter Jacket', 1, 'The zip broke mid-ski-trip. Had to buy an emergency layer at the resort. I am furious.',                                          DATEADD(DAY, -25, CURRENT_DATE)),
(15, 'ORD-10015', 'Summit Winter Jacket', 2, 'The zipper gets stuck halfway every single time. I''ve tried zipper wax with no luck at all.',                                    DATEADD(DAY, -27, CURRENT_DATE)),
(16, 'ORD-10016', 'Summit Winter Jacket', 1, 'Zipper pull came off in my hand on day two. Cheap hardware on a very expensive jacket.',                                          DATEADD(DAY, -28, CURRENT_DATE)),
(17, 'ORD-10017', 'Summit Winter Jacket', 1, 'The zip won''t budge at all now. Had to cut myself out of the jacket. Completely ridiculous.',                                    DATEADD(DAY, -30, CURRENT_DATE)),
(18, 'ORD-10018', 'Summit Winter Jacket', 2, 'Zipper is clearly defective. It slides down on its own and won''t stay zipped during activity.',                                  DATEADD(DAY, -32, CURRENT_DATE)),
(19, 'ORD-10019', 'Summit Winter Jacket', 1, 'Broken zipper after just three wears. I am requesting a full refund immediately.',                                                DATEADD(DAY, -33, CURRENT_DATE)),
(20, 'ORD-10020', 'Summit Winter Jacket', 1, 'The zipper mechanism is totally flawed. It snags on the lining and then broke entirely.',                                        DATEADD(DAY, -35, CURRENT_DATE)),
(21, 'ORD-10021', 'Summit Winter Jacket', 2, 'I love the style and warmth but the zipper broke after less than a month. Really let me down.',                                   DATEADD(DAY, -37, CURRENT_DATE)),
(22, 'ORD-10022', 'Summit Winter Jacket', 1, 'Defective zipper. It literally fell apart on the trail. This is a $189 jacket — the zip can''t last a week?',                    DATEADD(DAY, -38, CURRENT_DATE)),
(23, 'ORD-10023', 'Summit Winter Jacket', 1, 'The zip broke on the first day of my camping trip. Absolutely ruined the whole experience.',                                      DATEADD(DAY, -40, CURRENT_DATE)),
(24, 'ORD-10024', 'Summit Winter Jacket', 2, 'Zipper is stuck and won''t move at all. I''ve seen multiple people report this exact same problem.',                              DATEADD(DAY, -42, CURRENT_DATE)),
(25, 'ORD-10025', 'Summit Winter Jacket', 1, 'Sending this back for a refund. The zipper broke in two places and the jacket is unwearable.',                                    DATEADD(DAY, -44, CURRENT_DATE)),
(26, 'ORD-10026', 'Summit Winter Jacket', 1, 'The zip pull separated from the slider track on day one. How does QC miss something this obvious?',                              DATEADD(DAY, -45, CURRENT_DATE)),
(27, 'ORD-10027', 'Summit Winter Jacket', 2, 'Zipper won''t zip closed anymore after a week. The jacket is beautiful but completely non-functional.',                           DATEADD(DAY, -47, CURRENT_DATE)),
(28, 'ORD-10028', 'Summit Winter Jacket', 1, 'Returning this immediately. The zip broke after just the first wash cycle. Unacceptable.',                                        DATEADD(DAY, -49, CURRENT_DATE)),
(29, 'ORD-10029', 'Summit Winter Jacket', 1, 'The zipper failed on the mountain. I was left freezing. This is genuinely dangerous for winter use.',                             DATEADD(DAY, -50, CURRENT_DATE)),
(30, 'ORD-10030', 'Summit Winter Jacket', 2, 'Zipper sticks badly every morning. I have to fight it for five minutes. There is clearly a design flaw.',                        DATEADD(DAY, -52, CURRENT_DATE)),
(31, 'ORD-10031', 'Summit Winter Jacket', 1, 'Broken zipper after two uses. I''ve read other reviews saying the same thing. Why hasn''t this been fixed?',                     DATEADD(DAY, -54, CURRENT_DATE)),
(32, 'ORD-10032', 'Summit Winter Jacket', 1, 'Zip literally fell off the jacket. I want a full refund and an explanation.',                                                     DATEADD(DAY, -55, CURRENT_DATE)),
(33, 'ORD-10033', 'Summit Winter Jacket', 2, 'The zipper won''t latch at the bottom. I can''t zip the jacket up at all without it immediately coming undone.',                  DATEADD(DAY, -57, CURRENT_DATE)),
(34, 'ORD-10034', 'Summit Winter Jacket', 1, 'This zipper is complete garbage. It broke on first use in freezing temperatures when I needed it most.',                         DATEADD(DAY, -59, CURRENT_DATE)),
(35, 'ORD-10035', 'Summit Winter Jacket', 1, 'Three people in my hiking group bought this jacket. All three had zipper problems within a week of purchase.',                    DATEADD(DAY, -61, CURRENT_DATE)),
(36, 'ORD-10036', 'Summit Winter Jacket', 2, 'The zipper slides down by itself whenever I''m active outside. It''s a defective slider mechanism.',                              DATEADD(DAY, -63, CURRENT_DATE)),
(37, 'ORD-10037', 'Summit Winter Jacket', 1, 'Zip broke mid-hike two miles from the trailhead in near-zero temperatures. Completely unacceptable.',                            DATEADD(DAY, -65, CURRENT_DATE)),
(38, 'ORD-10038', 'Summit Winter Jacket', 1, 'The zipper track separated from the jacket fabric entirely. This is a fundamental and serious quality issue.',                    DATEADD(DAY, -67, CURRENT_DATE)),
-- Summit Winter Jacket – positive reviews (ratings 4–5, rows 39–44)
(39, 'ORD-10039', 'Summit Winter Jacket', 5, 'Incredibly warm and the fit is perfect. Used it for a week in the Rockies with absolutely no issues.',                           DATEADD(DAY, -70, CURRENT_DATE)),
(40, 'ORD-10040', 'Summit Winter Jacket', 5, 'Best winter jacket I''ve ever owned. Fits true to size and keeps me warm on the slopes all day.',                                 DATEADD(DAY, -72, CURRENT_DATE)),
(41, 'ORD-10041', 'Summit Winter Jacket', 4, 'Really love this jacket. A little pricey but the insulation quality is absolutely top notch.',                                   DATEADD(DAY, -75, CURRENT_DATE)),
(42, 'ORD-10042', 'Summit Winter Jacket', 5, 'Excellent quality and very warm. Fast shipping too. Would buy again without hesitation.',                                         DATEADD(DAY, -77, CURRENT_DATE)),
(43, 'ORD-10043', 'Summit Winter Jacket', 4, 'Great jacket overall. The material is windproof and water resistant. Very happy with this purchase.',                             DATEADD(DAY, -80, CURRENT_DATE)),
(44, 'ORD-10044', 'Summit Winter Jacket', 5, 'Survived a brutal cold snap wearing this all week. Warm, lightweight, and stylish. Highly recommend.',                            DATEADD(DAY, -83, CURRENT_DATE)),
-- Trailhead Fleece (rows 45–49)
(45, 'ORD-10045', 'Trailhead Fleece',     5, 'Super soft and warm. Arrived in two days and fits perfectly. Excellent value for the price.',                                     DATEADD(DAY, -4,  CURRENT_DATE)),
(46, 'ORD-10046', 'Trailhead Fleece',     4, 'Really nice fleece. Shipping was fast and the color matches the website photo exactly.',                                          DATEADD(DAY, -21, CURRENT_DATE)),
(47, 'ORD-10047', 'Trailhead Fleece',     3, 'Decent fleece but it runs a bit large. I''d recommend sizing down if you want a more fitted look.',                               DATEADD(DAY, -38, CURRENT_DATE)),
(48, 'ORD-10048', 'Trailhead Fleece',     5, 'Bought two of these for a camping trip. Both held up great and washed well without any pilling.',                                 DATEADD(DAY, -58, CURRENT_DATE)),
(49, 'ORD-10049', 'Trailhead Fleece',     2, 'Started pilling after just a few washes. Expected much better quality at this price point.',                                      DATEADD(DAY, -74, CURRENT_DATE)),
-- Basecamp Boots (rows 50–54)
(50, 'ORD-10050', 'Basecamp Boots',       5, 'Incredibly comfortable from day one. No break-in period needed at all. Perfect for long hikes.',                                 DATEADD(DAY, -10, CURRENT_DATE)),
(51, 'ORD-10051', 'Basecamp Boots',       4, 'Good waterproofing and solid grip on wet trails. Fast shipping and arrived well packaged.',                                       DATEADD(DAY, -26, CURRENT_DATE)),
(52, 'ORD-10052', 'Basecamp Boots',       2, 'The sizing runs quite narrow. I normally wear D width and had to return these for a wide fitting.',                               DATEADD(DAY, -43, CURRENT_DATE)),
(53, 'ORD-10053', 'Basecamp Boots',       5, 'Wore these on a 10-day backpacking trip and they held up perfectly. Zero blisters the whole time.',                              DATEADD(DAY, -62, CURRENT_DATE)),
(54, 'ORD-10054', 'Basecamp Boots',       3, 'Boots are OK but the sole started to separate a little after heavy daily use. A minor but real concern.',                        DATEADD(DAY, -79, CURRENT_DATE)),
-- Alpine Gloves (rows 55–58)
(55, 'ORD-10055', 'Alpine Gloves',        5, 'Warmest gloves I''ve ever owned. Great for skiing and they arrived two days ahead of schedule.',                                  DATEADD(DAY, -7,  CURRENT_DATE)),
(56, 'ORD-10056', 'Alpine Gloves',        4, 'Good insulation and touchscreen-compatible fingertips. Very happy with this purchase.',                                           DATEADD(DAY, -29, CURRENT_DATE)),
(57, 'ORD-10057', 'Alpine Gloves',        3, 'Nice gloves but the sizing is off. The medium was too small for my hands, had to exchange.',                                      DATEADD(DAY, -56, CURRENT_DATE)),
(58, 'ORD-10058', 'Alpine Gloves',        5, 'Excellent quality for the price. Used them all winter season and they still look brand new.',                                     DATEADD(DAY, -82, CURRENT_DATE)),
-- Ridgeline Backpack (rows 59–62)
(59, 'ORD-10059', 'Ridgeline Backpack',   5, 'Perfect for day hikes. Lots of storage pockets, comfortable straps, and arrived ahead of time.',                                 DATEADD(DAY, -13, CURRENT_DATE)),
(60, 'ORD-10060', 'Ridgeline Backpack',   4, 'Solid construction with a good rain cover included. Fits very comfortably on my back.',                                           DATEADD(DAY, -34, CURRENT_DATE)),
(61, 'ORD-10061', 'Ridgeline Backpack',   2, 'One of the shoulder strap buckles broke after only two trips. Disappointing for the price paid.',                                 DATEADD(DAY, -51, CURRENT_DATE)),
(62, 'ORD-10062', 'Ridgeline Backpack',   5, 'Best backpack I''ve used for multi-day hikes. Tons of well-organized pockets and very comfortable.',                              DATEADD(DAY, -76, CURRENT_DATE));


-- ============================================================
-- Table 2: MCP_HOL.SALES.SALES_FACT
-- ============================================================
CREATE OR REPLACE TABLE MCP_HOL.SALES.SALES_FACT (
    ORDER_ID    STRING,
    PRODUCT     STRING,
    REGION      STRING,
    UNITS       INT,
    UNIT_PRICE  NUMBER(10,2),
    REVENUE     NUMBER(12,2),
    REFUND_AMT  NUMBER(12,2),
    ORDER_DATE  DATE
);

INSERT INTO MCP_HOL.SALES.SALES_FACT (ORDER_ID, PRODUCT, REGION, UNITS, UNIT_PRICE, REVENUE, REFUND_AMT, ORDER_DATE)
VALUES
-- Summit Winter Jacket – 15 rows; UNITS=320, REFUND_AMT=$9,000 (unit_price=$189.00)
('ORD-20001', 'Summit Winter Jacket', 'Northeast', 20, 189.00,  3780.00,  756.00, DATEADD(DAY, -5,   CURRENT_DATE)),
('ORD-20002', 'Summit Winter Jacket', 'West',      25, 189.00,  4725.00,  945.00, DATEADD(DAY, -12,  CURRENT_DATE)),
('ORD-20003', 'Summit Winter Jacket', 'Midwest',   18, 189.00,  3402.00,  378.00, DATEADD(DAY, -19,  CURRENT_DATE)),
('ORD-20004', 'Summit Winter Jacket', 'South',     22, 189.00,  4158.00,  630.00, DATEADD(DAY, -26,  CURRENT_DATE)),
('ORD-20005', 'Summit Winter Jacket', 'Northeast', 15, 189.00,  2835.00,  567.00, DATEADD(DAY, -34,  CURRENT_DATE)),
('ORD-20006', 'Summit Winter Jacket', 'West',      30, 189.00,  5670.00, 1134.00, DATEADD(DAY, -41,  CURRENT_DATE)),
('ORD-20007', 'Summit Winter Jacket', 'Midwest',   20, 189.00,  3780.00,  378.00, DATEADD(DAY, -48,  CURRENT_DATE)),
('ORD-20008', 'Summit Winter Jacket', 'South',     18, 189.00,  3402.00,  756.00, DATEADD(DAY, -55,  CURRENT_DATE)),
('ORD-20009', 'Summit Winter Jacket', 'Northeast', 25, 189.00,  4725.00,  945.00, DATEADD(DAY, -62,  CURRENT_DATE)),
('ORD-20010', 'Summit Winter Jacket', 'West',      22, 189.00,  4158.00,  630.00, DATEADD(DAY, -70,  CURRENT_DATE)),
('ORD-20011', 'Summit Winter Jacket', 'Midwest',   20, 189.00,  3780.00,  378.00, DATEADD(DAY, -78,  CURRENT_DATE)),
('ORD-20012', 'Summit Winter Jacket', 'South',     25, 189.00,  4725.00,  504.00, DATEADD(DAY, -85,  CURRENT_DATE)),
('ORD-20013', 'Summit Winter Jacket', 'Northeast', 30, 189.00,  5670.00,  999.00, DATEADD(DAY, -92,  CURRENT_DATE)),
('ORD-20014', 'Summit Winter Jacket', 'West',      10, 189.00,  1890.00,    0.00, DATEADD(DAY, -100, CURRENT_DATE)),
('ORD-20015', 'Summit Winter Jacket', 'Midwest',   20, 189.00,  3780.00,    0.00, DATEADD(DAY, -110, CURRENT_DATE)),
-- Trailhead Fleece – 13 rows (unit_price=$89.00)
('ORD-20016', 'Trailhead Fleece', 'Northeast', 15, 89.00, 1335.00,   0.00, DATEADD(DAY, -4,   CURRENT_DATE)),
('ORD-20017', 'Trailhead Fleece', 'West',      20, 89.00, 1780.00,   0.00, DATEADD(DAY, -11,  CURRENT_DATE)),
('ORD-20018', 'Trailhead Fleece', 'Midwest',   12, 89.00, 1068.00,  89.00, DATEADD(DAY, -18,  CURRENT_DATE)),
('ORD-20019', 'Trailhead Fleece', 'South',     18, 89.00, 1602.00,   0.00, DATEADD(DAY, -25,  CURRENT_DATE)),
('ORD-20020', 'Trailhead Fleece', 'Northeast', 25, 89.00, 2225.00,   0.00, DATEADD(DAY, -32,  CURRENT_DATE)),
('ORD-20021', 'Trailhead Fleece', 'West',      10, 89.00,  890.00,   0.00, DATEADD(DAY, -40,  CURRENT_DATE)),
('ORD-20022', 'Trailhead Fleece', 'Midwest',   22, 89.00, 1958.00,  89.00, DATEADD(DAY, -47,  CURRENT_DATE)),
('ORD-20023', 'Trailhead Fleece', 'South',     15, 89.00, 1335.00,   0.00, DATEADD(DAY, -54,  CURRENT_DATE)),
('ORD-20024', 'Trailhead Fleece', 'Northeast', 20, 89.00, 1780.00,   0.00, DATEADD(DAY, -63,  CURRENT_DATE)),
('ORD-20025', 'Trailhead Fleece', 'West',      18, 89.00, 1602.00,   0.00, DATEADD(DAY, -72,  CURRENT_DATE)),
('ORD-20026', 'Trailhead Fleece', 'Midwest',   25, 89.00, 2225.00, 178.00, DATEADD(DAY, -80,  CURRENT_DATE)),
('ORD-20027', 'Trailhead Fleece', 'South',     12, 89.00, 1068.00,   0.00, DATEADD(DAY, -88,  CURRENT_DATE)),
('ORD-20028', 'Trailhead Fleece', 'Northeast', 30, 89.00, 2670.00,   0.00, DATEADD(DAY, -96,  CURRENT_DATE)),
-- Basecamp Boots – 13 rows (unit_price=$149.00)
('ORD-20029', 'Basecamp Boots', 'West',      10, 149.00, 1490.00,   0.00, DATEADD(DAY, -6,   CURRENT_DATE)),
('ORD-20030', 'Basecamp Boots', 'South',     14, 149.00, 2086.00, 149.00, DATEADD(DAY, -14,  CURRENT_DATE)),
('ORD-20031', 'Basecamp Boots', 'Northeast', 18, 149.00, 2682.00,   0.00, DATEADD(DAY, -22,  CURRENT_DATE)),
('ORD-20032', 'Basecamp Boots', 'Midwest',   12, 149.00, 1788.00,   0.00, DATEADD(DAY, -30,  CURRENT_DATE)),
('ORD-20033', 'Basecamp Boots', 'West',      20, 149.00, 2980.00, 298.00, DATEADD(DAY, -38,  CURRENT_DATE)),
('ORD-20034', 'Basecamp Boots', 'South',      8, 149.00, 1192.00,   0.00, DATEADD(DAY, -46,  CURRENT_DATE)),
('ORD-20035', 'Basecamp Boots', 'Northeast', 15, 149.00, 2235.00,   0.00, DATEADD(DAY, -53,  CURRENT_DATE)),
('ORD-20036', 'Basecamp Boots', 'Midwest',   22, 149.00, 3278.00, 149.00, DATEADD(DAY, -60,  CURRENT_DATE)),
('ORD-20037', 'Basecamp Boots', 'West',      10, 149.00, 1490.00,   0.00, DATEADD(DAY, -68,  CURRENT_DATE)),
('ORD-20038', 'Basecamp Boots', 'South',     16, 149.00, 2384.00,   0.00, DATEADD(DAY, -76,  CURRENT_DATE)),
('ORD-20039', 'Basecamp Boots', 'Northeast', 12, 149.00, 1788.00,   0.00, DATEADD(DAY, -84,  CURRENT_DATE)),
('ORD-20040', 'Basecamp Boots', 'Midwest',   18, 149.00, 2682.00, 298.00, DATEADD(DAY, -92,  CURRENT_DATE)),
('ORD-20041', 'Basecamp Boots', 'West',      14, 149.00, 2086.00,   0.00, DATEADD(DAY, -100, CURRENT_DATE)),
-- Alpine Gloves – 12 rows (unit_price=$45.00)
('ORD-20042', 'Alpine Gloves', 'Northeast', 30, 45.00, 1350.00,  0.00, DATEADD(DAY, -3,   CURRENT_DATE)),
('ORD-20043', 'Alpine Gloves', 'West',      25, 45.00, 1125.00,  0.00, DATEADD(DAY, -10,  CURRENT_DATE)),
('ORD-20044', 'Alpine Gloves', 'Midwest',   20, 45.00,  900.00, 45.00, DATEADD(DAY, -18,  CURRENT_DATE)),
('ORD-20045', 'Alpine Gloves', 'South',     35, 45.00, 1575.00,  0.00, DATEADD(DAY, -27,  CURRENT_DATE)),
('ORD-20046', 'Alpine Gloves', 'Northeast', 40, 45.00, 1800.00,  0.00, DATEADD(DAY, -36,  CURRENT_DATE)),
('ORD-20047', 'Alpine Gloves', 'West',      28, 45.00, 1260.00, 90.00, DATEADD(DAY, -45,  CURRENT_DATE)),
('ORD-20048', 'Alpine Gloves', 'Midwest',   22, 45.00,  990.00,  0.00, DATEADD(DAY, -54,  CURRENT_DATE)),
('ORD-20049', 'Alpine Gloves', 'South',     30, 45.00, 1350.00,  0.00, DATEADD(DAY, -63,  CURRENT_DATE)),
('ORD-20050', 'Alpine Gloves', 'Northeast', 25, 45.00, 1125.00, 45.00, DATEADD(DAY, -72,  CURRENT_DATE)),
('ORD-20051', 'Alpine Gloves', 'West',      35, 45.00, 1575.00,  0.00, DATEADD(DAY, -82,  CURRENT_DATE)),
('ORD-20052', 'Alpine Gloves', 'Midwest',   30, 45.00, 1350.00,  0.00, DATEADD(DAY, -93,  CURRENT_DATE)),
('ORD-20053', 'Alpine Gloves', 'South',     20, 45.00,  900.00,  0.00, DATEADD(DAY, -104, CURRENT_DATE)),
-- Ridgeline Backpack – 12 rows (unit_price=$129.00)
('ORD-20054', 'Ridgeline Backpack', 'Northeast', 12, 129.00, 1548.00,   0.00, DATEADD(DAY, -7,   CURRENT_DATE)),
('ORD-20055', 'Ridgeline Backpack', 'West',      15, 129.00, 1935.00,   0.00, DATEADD(DAY, -16,  CURRENT_DATE)),
('ORD-20056', 'Ridgeline Backpack', 'Midwest',   10, 129.00, 1290.00, 129.00, DATEADD(DAY, -24,  CURRENT_DATE)),
('ORD-20057', 'Ridgeline Backpack', 'South',     18, 129.00, 2322.00,   0.00, DATEADD(DAY, -33,  CURRENT_DATE)),
('ORD-20058', 'Ridgeline Backpack', 'Northeast', 20, 129.00, 2580.00,   0.00, DATEADD(DAY, -42,  CURRENT_DATE)),
('ORD-20059', 'Ridgeline Backpack', 'West',      14, 129.00, 1806.00, 258.00, DATEADD(DAY, -50,  CURRENT_DATE)),
('ORD-20060', 'Ridgeline Backpack', 'Midwest',   16, 129.00, 2064.00,   0.00, DATEADD(DAY, -59,  CURRENT_DATE)),
('ORD-20061', 'Ridgeline Backpack', 'South',     12, 129.00, 1548.00,   0.00, DATEADD(DAY, -68,  CURRENT_DATE)),
('ORD-20062', 'Ridgeline Backpack', 'Northeast', 22, 129.00, 2838.00, 129.00, DATEADD(DAY, -77,  CURRENT_DATE)),
('ORD-20063', 'Ridgeline Backpack', 'West',      10, 129.00, 1290.00,   0.00, DATEADD(DAY, -87,  CURRENT_DATE)),
('ORD-20064', 'Ridgeline Backpack', 'Midwest',   18, 129.00, 2322.00,   0.00, DATEADD(DAY, -98,  CURRENT_DATE)),
('ORD-20065', 'Ridgeline Backpack', 'South',     14, 129.00, 1806.00,   0.00, DATEADD(DAY, -108, CURRENT_DATE));
