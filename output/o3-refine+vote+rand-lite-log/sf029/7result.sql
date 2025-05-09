/* -----------------------------------------------------------------
   Daily product‑level sales report
   Period      : 30 days ending 6‑Feb‑2022 (inclusive)
   Distributor : Manufacturing
   Program     : Amazon Retail
-------------------------------------------------------------------*/
WITH
/* -------- 1.  Sales ------------------------------------------------*/
s AS (
    SELECT
        "DATE",
        "ASIN",
        "PROGRAM",
        "PERIOD",
        "DISTRIBUTOR_VIEW",
        SUM("ORDERED_UNITS")            AS "ORDERED_UNITS",
        SUM("ORDERED_REVENUE")          AS "ORDERED_REVENUE",
        SUM("SHIPPED_UNITS")            AS "SHIPPED_UNITS",
        SUM("SHIPPED_REVENUE")          AS "SHIPPED_REVENUE"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_SALES
    WHERE   "DISTRIBUTOR_VIEW" = 'Manufacturing'
        AND "PROGRAM"          = 'Amazon Retail'
        AND "PERIOD"           = 'DAILY'
        AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "DATE","ASIN","PROGRAM","PERIOD","DISTRIBUTOR_VIEW"
),

/* -------- 2.  Traffic ---------------------------------------------*/
t AS (
    SELECT
        "DATE",
        "ASIN",
        "PROGRAM",
        "PERIOD",
        "DISTRIBUTOR_VIEW",
        SUM("GLANCE_VIEWS")            AS "GLANCE_VIEWS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_TRAFFIC
    WHERE   "DISTRIBUTOR_VIEW" = 'Manufacturing'
        AND "PROGRAM"          = 'Amazon Retail'
        AND "PERIOD"           = 'DAILY'
        AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "DATE","ASIN","PROGRAM","PERIOD","DISTRIBUTOR_VIEW"
),

/* -------- 3.  Inventory -------------------------------------------*/
i AS (
    SELECT
        "DATE",
        "ASIN",
        "PROGRAM",
        "PERIOD",
        "DISTRIBUTOR_VIEW",
        AVG("PROCURABLE_PRODUCT_OOS")      AS "AVG_PROCURABLE_PRODUCT_OOS",
        SUM("SELLABLE_ON_HAND_UNITS")      AS "SELLABLE_ON_HAND_UNITS",
        SUM("SELLABLE_ON_HAND_INVENTORY")  AS "SELLABLE_ON_HAND_VALUE",
        SUM("NET_RECEIVED_UNITS")          AS "NET_RECEIVED_UNITS",
        SUM("NET_RECEIVED")                AS "NET_RECEIVED_VALUE",
        SUM("OPEN_PURCHASE_ORDER_QUANTITY")AS "OPEN_PURCHASE_ORDER_QTY",
        SUM("UNFILLED_CUSTOMER_ORDERED_UNITS") AS "UNFILLED_CUSTOMER_ORDERED_UNITS",
        AVG("VENDOR_CONFIRMATION_RATE")    AS "AVG_VENDOR_CONFIRMATION_RATE",
        AVG("RECEIVE_FILL_RATE")           AS "AVG_RECEIVE_FILL_RATE",
        AVG("SELL_THROUGH_RATE")           AS "AVG_SELL_THROUGH_RATE",
        AVG("OVERALL_VENDOR_LEAD_TIME_DAYS")AS "AVG_VENDOR_LEAD_TIME_DAYS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_INVENTORY
    WHERE   "DISTRIBUTOR_VIEW" = 'Manufacturing'
        AND "PROGRAM"          = 'Amazon Retail'
        AND "PERIOD"           = 'DAILY'
        AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "DATE","ASIN","PROGRAM","PERIOD","DISTRIBUTOR_VIEW"
),

/* -------- 4.  Net PPM ---------------------------------------------*/
n AS (
    SELECT
        "DATE",
        "ASIN",
        "PROGRAM",
        "PERIOD",
        "DISTRIBUTOR_VIEW",
        AVG("NET_PPM")                    AS "AVG_NET_PPM"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_NET_PPM
    WHERE   "DISTRIBUTOR_VIEW" = 'Manufacturing'
        AND "PROGRAM"          = 'Amazon Retail'
        AND "PERIOD"           = 'DAILY'
        AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "DATE","ASIN","PROGRAM","PERIOD","DISTRIBUTOR_VIEW"
)

/* -------- 5.  Final daily report ----------------------------------*/
SELECT
    s."DATE",
    s."ASIN",

    /* --- Sales metrics --- */
    s."ORDERED_UNITS"                              AS "TOTAL_ORDERED_UNITS",
    s."ORDERED_REVENUE"                            AS "TOTAL_ORDERED_REVENUE",
    CASE WHEN s."ORDERED_UNITS" <> 0
         THEN s."ORDERED_REVENUE" / s."ORDERED_UNITS"
    END                                            AS "AVG_SELLING_PRICE",

    /* --- Traffic metrics --- */
    t."GLANCE_VIEWS",
    CASE WHEN t."GLANCE_VIEWS" <> 0
         THEN s."ORDERED_UNITS" / t."GLANCE_VIEWS"
    END                                            AS "CONVERSION_RATE",

    /* --- Shipment metrics --- */
    s."SHIPPED_UNITS",
    s."SHIPPED_REVENUE",

    /* --- Profitability --- */
    n."AVG_NET_PPM",

    /* --- Inventory & operational --- */
    i."AVG_PROCURABLE_PRODUCT_OOS",
    i."SELLABLE_ON_HAND_UNITS"                     AS "TOTAL_ON_HAND_UNITS",
    i."SELLABLE_ON_HAND_VALUE"                     AS "TOTAL_ON_HAND_VALUE",
    i."NET_RECEIVED_UNITS",
    i."NET_RECEIVED_VALUE",
    i."OPEN_PURCHASE_ORDER_QTY",
    i."UNFILLED_CUSTOMER_ORDERED_UNITS",
    i."AVG_VENDOR_CONFIRMATION_RATE",
    i."AVG_RECEIVE_FILL_RATE",
    i."AVG_SELL_THROUGH_RATE",
    i."AVG_VENDOR_LEAD_TIME_DAYS"

FROM s
LEFT JOIN t
       ON  t."DATE"              = s."DATE"
       AND t."ASIN"              = s."ASIN"
       AND t."PROGRAM"           = s."PROGRAM"
       AND t."PERIOD"            = s."PERIOD"
       AND t."DISTRIBUTOR_VIEW"  = s."DISTRIBUTOR_VIEW"
LEFT JOIN i
       ON  i."DATE"              = s."DATE"
       AND i."ASIN"              = s."ASIN"
       AND i."PROGRAM"           = s."PROGRAM"
       AND i."PERIOD"            = s."PERIOD"
       AND i."DISTRIBUTOR_VIEW"  = s."DISTRIBUTOR_VIEW"
LEFT JOIN n
       ON  n."DATE"              = s."DATE"
       AND n."ASIN"              = s."ASIN"
       AND n."PROGRAM"           = s."PROGRAM"
       AND n."PERIOD"            = s."PERIOD"
       AND n."DISTRIBUTOR_VIEW"  = s."DISTRIBUTOR_VIEW"

ORDER BY
    s."DATE",
    s."ASIN";