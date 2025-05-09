WITH
-- 30‑day window
date_window AS (
    SELECT
        TO_DATE('2022-01-08')   AS "START_DATE",
        TO_DATE('2022-02-06')   AS "END_DATE"
),

/* -------- source subsets (restricted to period, view, program and window) -------- */
sales AS (
    SELECT
        TO_DATE("DATE")                                AS "DATE",
        "ASIN",
        "ORDERED_UNITS",
        "ORDERED_REVENUE",
        "SHIPPED_UNITS",
        "SHIPPED_REVENUE"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_SALES s
         ,date_window d
    WHERE  s."PERIOD"          = 'DAILY'
      AND  s."DISTRIBUTOR_VIEW"= 'Manufacturing'
      AND  s."PROGRAM"         = 'Amazon Retail'
      AND  TO_DATE(s."DATE") BETWEEN d."START_DATE" AND d."END_DATE"
),
traffic AS (
    SELECT
        TO_DATE("DATE")          AS "DATE",
        "ASIN",
        "GLANCE_VIEWS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_TRAFFIC t
         ,date_window d
    WHERE  t."PERIOD"           = 'DAILY'
      AND  t."DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND  t."PROGRAM"          = 'Amazon Retail'
      AND  TO_DATE(t."DATE") BETWEEN d."START_DATE" AND d."END_DATE"
),
inventory AS (
    SELECT
        TO_DATE("DATE")                               AS "DATE",
        "ASIN",
        "PROCURABLE_PRODUCT_OOS",
        "SELLABLE_ON_HAND_UNITS",
        "UNSELLABLE_ON_HAND_UNITS",
        "SELLABLE_ON_HAND_INVENTORY",
        "UNSELLABLE_ON_HAND_INVENTORY",
        "NET_RECEIVED_UNITS",
        "NET_RECEIVED",
        "OPEN_PURCHASE_ORDER_QUANTITY",
        "UNFILLED_CUSTOMER_ORDERED_UNITS",
        "VENDOR_CONFIRMATION_RATE",
        "RECEIVE_FILL_RATE",
        "SELL_THROUGH_RATE",
        "OVERALL_VENDOR_LEAD_TIME_DAYS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_INVENTORY i
         ,date_window d
    WHERE  i."PERIOD"           = 'DAILY'
      AND  i."DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND  i."PROGRAM"          = 'Amazon Retail'
      AND  TO_DATE(i."DATE") BETWEEN d."START_DATE" AND d."END_DATE"
),
ppm AS (
    SELECT
        TO_DATE("DATE")           AS "DATE",
        "ASIN",
        "NET_PPM"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_NET_PPM p
         ,date_window d
    WHERE  p."PERIOD"           = 'DAILY'
      AND  p."DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND  p."PROGRAM"          = 'Amazon Retail'
      AND  TO_DATE(p."DATE") BETWEEN d."START_DATE" AND d."END_DATE"
)

/* -------- final daily product report -------- */
SELECT
      s."DATE"
    , s."ASIN"
    -- ordered / revenue
    , COALESCE(s."ORDERED_UNITS",0)                                   AS "TOTAL_ORDERED_UNITS"
    , COALESCE(s."ORDERED_REVENUE",0)                                 AS "ORDERED_REVENUE"
    , CASE WHEN s."ORDERED_UNITS" > 0
           THEN s."ORDERED_REVENUE" / s."ORDERED_UNITS"
      END                                                             AS "AVG_SELLING_PRICE"
    -- traffic
    , t."GLANCE_VIEWS"
    , CASE WHEN t."GLANCE_VIEWS" > 0
           THEN s."ORDERED_UNITS" / t."GLANCE_VIEWS"
      END                                                             AS "CONVERSION_RATE"
    -- shipped
    , s."SHIPPED_UNITS"
    , s."SHIPPED_REVENUE"
    -- ppm
    , p."NET_PPM"                                                     AS "AVG_NET_PPM"
    -- inventory / supply metrics
    , i."PROCURABLE_PRODUCT_OOS"                                      AS "AVG_PROCURABLE_PRODUCT_OOS"
    , (i."SELLABLE_ON_HAND_UNITS"   + i."UNSELLABLE_ON_HAND_UNITS")   AS "TOTAL_ON_HAND_UNITS"
    , (i."SELLABLE_ON_HAND_INVENTORY"+ i."UNSELLABLE_ON_HAND_INVENTORY") AS "TOTAL_ON_HAND_VALUE"
    , i."NET_RECEIVED_UNITS"                                          AS "NET_RECEIVED_UNITS"
    , i."NET_RECEIVED"                                                AS "NET_RECEIVED_VALUE"
    , i."OPEN_PURCHASE_ORDER_QUANTITY"                                AS "OPEN_PO_QUANTITY"
    , i."UNFILLED_CUSTOMER_ORDERED_UNITS"                             AS "UNFILLED_CUSTOMER_ORDERED_UNITS"
    , i."VENDOR_CONFIRMATION_RATE"                                    AS "AVG_VENDOR_CONFIRMATION_RATE"
    , i."RECEIVE_FILL_RATE"                                           AS "AVG_RECEIVE_FILL_RATE"
    , i."SELL_THROUGH_RATE"                                           AS "AVG_SELL_THROUGH_RATE"
    , i."OVERALL_VENDOR_LEAD_TIME_DAYS"                               AS "AVG_VENDOR_LEAD_TIME_DAYS"
FROM      sales      s
LEFT JOIN traffic    t ON t."DATE" = s."DATE"
                     AND t."ASIN" = s."ASIN"
LEFT JOIN inventory  i ON i."DATE" = s."DATE"
                     AND i."ASIN" = s."ASIN"
LEFT JOIN ppm        p ON p."DATE" = s."DATE"
                     AND p."ASIN" = s."ASIN"
ORDER BY s."DATE", s."ASIN";