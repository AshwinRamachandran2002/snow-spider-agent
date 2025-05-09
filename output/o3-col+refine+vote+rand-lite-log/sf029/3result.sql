/* Daily 30-day sales & operations report – Manufacturing distributor view */
WITH
/* 1.  Aggregate daily sales */
sales AS (
    SELECT
        "DATE",
        "ASIN",
        SUM("ORDERED_UNITS")   AS "ORDERED_UNITS",
        SUM("ORDERED_REVENUE") AS "ORDERED_REVENUE",
        SUM("SHIPPED_UNITS")   AS "SHIPPED_UNITS",
        SUM("SHIPPED_REVENUE") AS "SHIPPED_REVENUE"
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_SALES"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "PROGRAM"          = 'Amazon Retail'
      AND "PERIOD"           = 'DAILY'
      AND "DATE" BETWEEN '2022-01-07' AND '2022-02-05'        -- 30-day look-back
    GROUP BY "DATE","ASIN"
),

/* 2.  Aggregate daily traffic */
traffic AS (
    SELECT
        "DATE",
        "ASIN",
        SUM("GLANCE_VIEWS") AS "GLANCE_VIEWS"
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_TRAFFIC"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "PROGRAM"          = 'Amazon Retail'
      AND "PERIOD"           = 'DAILY'
      AND "DATE" BETWEEN '2022-01-07' AND '2022-02-05'
    GROUP BY "DATE","ASIN"
),

/* 3.  Average daily net-PPM */
ppm AS (
    SELECT
        "DATE",
        "ASIN",
        AVG("NET_PPM") AS "AVG_NET_PPM"
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_NET_PPM"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "PROGRAM"          = 'Amazon Retail'
      AND "PERIOD"           = 'DAILY'
      AND "DATE" BETWEEN '2022-01-07' AND '2022-02-05'
    GROUP BY "DATE","ASIN"
),

/* 4.  Average daily inventory & supply-chain metrics */
inv AS (
    SELECT
        "DATE",
        "ASIN",
        AVG("PROCURABLE_PRODUCT_OOS")          AS "AVG_PROCURABLE_OOS",
        AVG("VENDOR_CONFIRMATION_RATE")        AS "AVG_VENDOR_CONFIRMATION_RATE",
        AVG("RECEIVE_FILL_RATE")               AS "AVG_RECEIVE_FILL_RATE",
        AVG("SELL_THROUGH_RATE")               AS "AVG_SELL_THROUGH_RATE",
        AVG("OVERALL_VENDOR_LEAD_TIME_DAYS")   AS "AVG_VENDOR_LEAD_TIME",
        AVG("OPEN_PURCHASE_ORDER_QUANTITY")    AS "OPEN_PO_QTY",
        AVG("UNFILLED_CUSTOMER_ORDERED_UNITS") AS "UNFILLED_CUSTOMER_ORDERED_UNITS",
        AVG("NET_RECEIVED_UNITS")              AS "NET_RECEIVED_UNITS",
        AVG("NET_RECEIVED")                    AS "NET_RECEIVED_VALUE",
        AVG("SELLABLE_ON_HAND_UNITS" + "UNSELLABLE_ON_HAND_UNITS")
                                               AS "ON_HAND_UNITS"
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_INVENTORY"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "PROGRAM"          = 'Amazon Retail'
      AND "PERIOD"           = 'DAILY'
      AND "DATE" BETWEEN '2022-01-07' AND '2022-02-05'
    GROUP BY "DATE","ASIN"
),

/* 5.  Combine all sources */
daily_report AS (
    SELECT
        s."DATE",
        s."ASIN",

        /* Sales */
        s."ORDERED_UNITS"                                           AS "TOTAL_ORDERED_UNITS",
        s."ORDERED_REVENUE"                                         AS "TOTAL_ORDERED_REVENUE",
        CASE WHEN s."ORDERED_UNITS" > 0
             THEN s."ORDERED_REVENUE" / s."ORDERED_UNITS"
        END                                                         AS "AVG_SELLING_PRICE",

        /* Traffic */
        t."GLANCE_VIEWS",
        CASE WHEN t."GLANCE_VIEWS" > 0
             THEN s."ORDERED_UNITS" / t."GLANCE_VIEWS"
        END                                                         AS "CONVERSION_RATE",

        /* Shipments */
        s."SHIPPED_UNITS",
        s."SHIPPED_REVENUE",

        /* Profitability */
        p."AVG_NET_PPM",

        /* Inventory & supply-chain */
        i."AVG_PROCURABLE_OOS",
        i."ON_HAND_UNITS",
        CASE WHEN s."ORDERED_UNITS" > 0
             THEN i."ON_HAND_UNITS" * (s."ORDERED_REVENUE" / s."ORDERED_UNITS")
        END                                                         AS "ON_HAND_VALUE",
        i."NET_RECEIVED_UNITS",
        i."NET_RECEIVED_VALUE",
        i."OPEN_PO_QTY",
        i."UNFILLED_CUSTOMER_ORDERED_UNITS",
        i."AVG_VENDOR_CONFIRMATION_RATE",
        i."AVG_RECEIVE_FILL_RATE",
        i."AVG_SELL_THROUGH_RATE",
        i."AVG_VENDOR_LEAD_TIME"
    FROM sales   s
    LEFT JOIN traffic t ON t."DATE" = s."DATE" AND t."ASIN" = s."ASIN"
    LEFT JOIN ppm     p ON p."DATE" = s."DATE" AND p."ASIN" = s."ASIN"
    LEFT JOIN inv     i ON i."DATE" = s."DATE" AND i."ASIN" = s."ASIN"
)

SELECT *
FROM daily_report
ORDER BY "DATE", "ASIN";