WITH
/*------------------------ 30‑day calendar window ------------------------*/
dates AS (
    SELECT
        TO_DATE('2022-02-06') - SEQ4() AS "DATE"
    FROM TABLE(GENERATOR(ROWCOUNT => 30))
),

/*------------------------ SALES ----------------------------------------*/
sales AS (
    SELECT
        s."DATE",
        s."ASIN",
        s."ORDERED_UNITS",
        s."ORDERED_REVENUE",
        s."SHIPPED_UNITS",
        s."SHIPPED_REVENUE"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_SALES s
    WHERE s."PROGRAM"          = 'Amazon Retail'
      AND s."PERIOD"           = 'DAILY'
      AND s."DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND s."DATE" BETWEEN DATEADD(DAY,-29,'2022-02-06') AND '2022-02-06'
),

/*------------------------ TRAFFIC --------------------------------------*/
traffic AS (
    SELECT
        t."DATE",
        t."ASIN",
        t."GLANCE_VIEWS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_TRAFFIC t
    WHERE t."PROGRAM"          = 'Amazon Retail'
      AND t."PERIOD"           = 'DAILY'
      AND t."DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND t."DATE" BETWEEN DATEADD(DAY,-29,'2022-02-06') AND '2022-02-06'
),

/*------------------------ INVENTORY ------------------------------------*/
inv AS (
    SELECT
        i."DATE",
        i."ASIN",
        i."PROCURABLE_PRODUCT_OOS",
        i."SELLABLE_ON_HAND_UNITS",
        i."SELLABLE_ON_HAND_INVENTORY",
        i."NET_RECEIVED_UNITS",
        i."NET_RECEIVED",
        i."OPEN_PURCHASE_ORDER_QUANTITY",
        i."UNFILLED_CUSTOMER_ORDERED_UNITS",
        i."VENDOR_CONFIRMATION_RATE",
        i."RECEIVE_FILL_RATE",
        i."SELL_THROUGH_RATE",
        i."OVERALL_VENDOR_LEAD_TIME_DAYS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_INVENTORY i
    WHERE i."PROGRAM"          = 'Amazon Retail'
      AND i."PERIOD"           = 'DAILY'
      AND i."DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND i."DATE" BETWEEN DATEADD(DAY,-29,'2022-02-06') AND '2022-02-06'
),

/*------------------------ NET PPM --------------------------------------*/
nppm AS (
    SELECT
        n."DATE",
        n."ASIN",
        n."NET_PPM"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_NET_PPM n
    WHERE n."PROGRAM"          = 'Amazon Retail'
      AND n."PERIOD"           = 'DAILY'
      AND n."DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND n."DATE" BETWEEN DATEADD(DAY,-29,'2022-02-06') AND '2022-02-06'
)

/*=======================================================================*/
/*                DAILY DETAILED SALES REPORT ( Manufacturing )          */
/*=======================================================================*/
SELECT
    d."DATE",
    COALESCE(s."ASIN", t."ASIN", n."ASIN", i."ASIN")                           AS "ASIN",

    /* ---- Sales ---- */
    s."ORDERED_UNITS"                                                          AS "TOTAL_ORDERED_UNITS",
    s."ORDERED_REVENUE"                                                        AS "TOTAL_ORDERED_REVENUE",
    CASE WHEN s."ORDERED_UNITS" > 0
         THEN ROUND(s."ORDERED_REVENUE" / s."ORDERED_UNITS", 4)
    END                                                                        AS "AVG_SELLING_PRICE",

    /* ---- Traffic ---- */
    t."GLANCE_VIEWS",
    CASE WHEN t."GLANCE_VIEWS" > 0
         THEN ROUND(s."ORDERED_UNITS" / t."GLANCE_VIEWS", 4)
    END                                                                        AS "CONVERSION_RATE",

    /* ---- Shipments ---- */
    s."SHIPPED_UNITS",
    s."SHIPPED_REVENUE",

    /* ---- Profitability ---- */
    n."NET_PPM"                                                                AS "AVG_NET_PPM",

    /* ---- Inventory & Operations ---- */
    i."PROCURABLE_PRODUCT_OOS"                                                 AS "AVG_PROCURABLE_PRODUCT_OOS",
    i."SELLABLE_ON_HAND_UNITS"                                                 AS "ON_HAND_UNITS",
    i."SELLABLE_ON_HAND_INVENTORY"                                             AS "ON_HAND_INVENTORY_VALUE",
    i."NET_RECEIVED_UNITS"                                                     AS "NET_RECEIVED_UNITS",
    i."NET_RECEIVED"                                                           AS "NET_RECEIVED_VALUE",
    i."OPEN_PURCHASE_ORDER_QUANTITY",
    i."UNFILLED_CUSTOMER_ORDERED_UNITS",
    i."VENDOR_CONFIRMATION_RATE"                                               AS "AVG_VENDOR_CONFIRMATION_RATE",
    i."RECEIVE_FILL_RATE"                                                      AS "AVG_RECEIVE_FILL_RATE",
    i."SELL_THROUGH_RATE"                                                      AS "AVG_SELL_THROUGH_RATE",
    i."OVERALL_VENDOR_LEAD_TIME_DAYS"                                          AS "AVG_VENDOR_LEAD_TIME_DAYS"

FROM dates d
LEFT JOIN sales   s ON d."DATE" = s."DATE"
LEFT JOIN traffic t ON d."DATE" = t."DATE"   AND t."ASIN" = s."ASIN"
LEFT JOIN nppm    n ON d."DATE" = n."DATE"   AND n."ASIN" = COALESCE(s."ASIN", t."ASIN")
LEFT JOIN inv     i ON d."DATE" = i."DATE"   AND i."ASIN" = COALESCE(s."ASIN", t."ASIN", n."ASIN")

WHERE COALESCE(s."ASIN", t."ASIN", n."ASIN", i."ASIN") IS NOT NULL
ORDER BY d."DATE", "ASIN";