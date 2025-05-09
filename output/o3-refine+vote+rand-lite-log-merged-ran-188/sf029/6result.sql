/*  Daily detailed sales report for ‘Manufacturing’ – 30-day window prior to 06-Feb-2022  */

WITH sales AS (           -- demand & revenue
    SELECT
        "DATE",
        "ASIN",
        SUM("ORDERED_UNITS")      AS "ORDERED_UNITS",
        SUM("ORDERED_REVENUE")    AS "ORDERED_REVENUE",
        SUM("SHIPPED_UNITS")      AS "SHIPPED_UNITS",
        SUM("SHIPPED_REVENUE")    AS "SHIPPED_REVENUE"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "PROGRAM"          = 'Amazon Retail'
      AND "PERIOD"           = 'DAILY'
      AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "DATE", "ASIN"
),

traffic AS (              -- product page views
    SELECT
        "DATE",
        "ASIN",
        SUM("GLANCE_VIEWS") AS "GLANCE_VIEWS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "PROGRAM"          = 'Amazon Retail'
      AND "PERIOD"           = 'DAILY'
      AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "DATE", "ASIN"
),

inv AS (                  -- inventory & operational KPIs
    SELECT
        "DATE",
        "ASIN",
        AVG("PROCURABLE_PRODUCT_OOS")                            AS "AVG_PROCURABLE_PRODUCT_OOS",
        AVG("SELLABLE_ON_HAND_UNITS" + "UNSELLABLE_ON_HAND_UNITS")   AS "TOTAL_ON_HAND_UNITS",
        AVG("NET_RECEIVED_UNITS")                                AS "NET_RECEIVED_UNITS",
        AVG("OPEN_PURCHASE_ORDER_QUANTITY")                      AS "OPEN_PO_QTY",
        AVG("UNFILLED_CUSTOMER_ORDERED_UNITS")                   AS "UNFILLED_CUSTOMER_ORDERED_UNITS",
        AVG("VENDOR_CONFIRMATION_RATE")                          AS "AVG_VENDOR_CONFIRMATION_RATE",
        AVG("RECEIVE_FILL_RATE")                                 AS "AVG_RECEIVE_FILL_RATE",
        AVG("SELL_THROUGH_RATE")                                 AS "AVG_SELL_THROUGH_RATE",
        AVG("OVERALL_VENDOR_LEAD_TIME_DAYS")                     AS "AVG_VENDOR_LEAD_TIME_DAYS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "PROGRAM"          = 'Amazon Retail'
      AND "PERIOD"           = 'DAILY'
      AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "DATE", "ASIN"
),

ppm AS (                  -- profitability
    SELECT
        "DATE",
        "ASIN",
        AVG("NET_PPM") AS "AVG_NET_PPM"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_NET_PPM"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "PROGRAM"          = 'Amazon Retail'
      AND "PERIOD"           = 'DAILY'
      AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "DATE", "ASIN"
)

SELECT
    s."DATE",
    s."ASIN",

    /* demand metrics */
    s."ORDERED_UNITS",
    s."ORDERED_REVENUE",
    CASE WHEN s."ORDERED_UNITS" = 0 THEN NULL
         ELSE ROUND(s."ORDERED_REVENUE" / s."ORDERED_UNITS", 4) END                 AS "AVG_SELLING_PRICE",

    t."GLANCE_VIEWS",
    CASE WHEN t."GLANCE_VIEWS" = 0 THEN NULL
         ELSE ROUND(s."ORDERED_UNITS" / t."GLANCE_VIEWS", 4) END                    AS "CONVERSION_RATE",

    s."SHIPPED_UNITS",
    s."SHIPPED_REVENUE",

    /* profitability */
    p."AVG_NET_PPM",

    /* inventory & operations */
    i."AVG_PROCURABLE_PRODUCT_OOS",
    i."TOTAL_ON_HAND_UNITS",
    CASE
         WHEN s."ORDERED_UNITS" = 0 THEN NULL
         ELSE ROUND(i."TOTAL_ON_HAND_UNITS" * (s."ORDERED_REVENUE" / s."ORDERED_UNITS"), 4)
    END                                                                             AS "ON_HAND_VALUE",

    i."NET_RECEIVED_UNITS",
    CASE
         WHEN s."SHIPPED_UNITS" = 0 THEN NULL
         ELSE ROUND(i."NET_RECEIVED_UNITS" * (s."SHIPPED_REVENUE" / s."SHIPPED_UNITS"), 4)
    END                                                                             AS "NET_RECEIVED_VALUE",

    i."OPEN_PO_QTY",
    i."UNFILLED_CUSTOMER_ORDERED_UNITS",
    i."AVG_VENDOR_CONFIRMATION_RATE",
    i."AVG_RECEIVE_FILL_RATE",
    i."AVG_SELL_THROUGH_RATE",
    i."AVG_VENDOR_LEAD_TIME_DAYS"

FROM   sales   s
LEFT JOIN traffic t ON t."DATE" = s."DATE" AND t."ASIN" = s."ASIN"
LEFT JOIN inv     i ON i."DATE" = s."DATE" AND i."ASIN" = s."ASIN"
LEFT JOIN ppm     p ON p."DATE" = s."DATE" AND p."ASIN" = s."ASIN"
ORDER BY s."DATE" ASC, s."ASIN" ASC;