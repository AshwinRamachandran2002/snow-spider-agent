/*  Daily detailed Manufacturing report : 2022-01-07  →  2022-02-06  */

WITH sales AS (          /* ordered / shipped information */
    SELECT  TO_DATE("DATE")          AS "DATE",
            "ASIN",
            SUM("ORDERED_UNITS")     AS "TOTAL_ORDERED_UNITS",
            SUM("ORDERED_REVENUE")   AS "ORDERED_REVENUE",
            SUM("SHIPPED_UNITS")     AS "SHIPPED_UNITS",
            SUM("SHIPPED_REVENUE")   AS "SHIPPED_REVENUE"
    FROM    AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES"
    WHERE   "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND   "PROGRAM"          = 'Amazon Retail'
      AND   "PERIOD"           = 'DAILY'
      AND   TO_DATE("DATE") BETWEEN '2022-01-07' AND '2022-02-06'
    GROUP BY TO_DATE("DATE"), "ASIN"
),
traffic AS (             /* glance views */
    SELECT  TO_DATE("DATE")      AS "DATE",
            "ASIN",
            SUM("GLANCE_VIEWS")  AS "GLANCE_VIEWS"
    FROM    AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC"
    WHERE   "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND   "PROGRAM"          = 'Amazon Retail'
      AND   "PERIOD"           = 'DAILY'
      AND   TO_DATE("DATE") BETWEEN '2022-01-07' AND '2022-02-06'
    GROUP BY TO_DATE("DATE"), "ASIN"
),
inventory AS (           /* inventory & operational metrics */
    SELECT  TO_DATE("DATE")                      AS "DATE",
            "ASIN",
            AVG("PROCURABLE_PRODUCT_OOS")        AS "AVG_PROCURABLE_OOS",
            SUM("SELLABLE_ON_HAND_UNITS")        AS "SELLABLE_ON_HAND_UNITS",
            SUM("UNSELLABLE_ON_HAND_UNITS")      AS "UNSELLABLE_ON_HAND_UNITS",
            SUM("NET_RECEIVED_UNITS")            AS "NET_RECEIVED_UNITS",
            SUM("NET_RECEIVED")                  AS "NET_RECEIVED_VALUE",
            SUM("OPEN_PURCHASE_ORDER_QUANTITY")  AS "OPEN_PURCHASE_ORDER_QUANTITY",
            SUM("UNFILLED_CUSTOMER_ORDERED_UNITS") AS "UNFILLED_CUSTOMER_ORDERED_UNITS",
            AVG("VENDOR_CONFIRMATION_RATE")      AS "VENDOR_CONFIRMATION_RATE",
            AVG("RECEIVE_FILL_RATE")             AS "RECEIVE_FILL_RATE",
            AVG("SELL_THROUGH_RATE")             AS "SELL_THROUGH_RATE",
            AVG("OVERALL_VENDOR_LEAD_TIME_DAYS") AS "OVERALL_VENDOR_LEAD_TIME_DAYS"
    FROM    AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY"
    WHERE   "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND   "PROGRAM"          = 'Amazon Retail'
      AND   "PERIOD"           = 'DAILY'
      AND   TO_DATE("DATE") BETWEEN '2022-01-07' AND '2022-02-06'
    GROUP BY TO_DATE("DATE"), "ASIN"
),
netppm AS (              /* profitability metric */
    SELECT  TO_DATE("DATE")      AS "DATE",
            "ASIN",
            AVG("NET_PPM")       AS "AVG_NET_PPM"
    FROM    AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_NET_PPM"
    WHERE   "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND   "PROGRAM"          = 'Amazon Retail'
      AND   "PERIOD"           = 'DAILY'
      AND   TO_DATE("DATE") BETWEEN '2022-01-07' AND '2022-02-06'
    GROUP BY TO_DATE("DATE"), "ASIN"
)

SELECT
    "DATE",
    "ASIN",

    /* --- Sales / Traffic --- */
    NVL(s."TOTAL_ORDERED_UNITS", 0)                     AS "TOTAL_ORDERED_UNITS",
    NVL(s."ORDERED_REVENUE",     0)                     AS "ORDERED_REVENUE",
    CASE WHEN NVL(s."TOTAL_ORDERED_UNITS",0) > 0
         THEN s."ORDERED_REVENUE" / s."TOTAL_ORDERED_UNITS"
    END                                                 AS "AVG_SELLING_PRICE",

    NVL(t."GLANCE_VIEWS", 0)                            AS "GLANCE_VIEWS",
    CASE WHEN NVL(t."GLANCE_VIEWS",0) > 0
         THEN NVL(s."TOTAL_ORDERED_UNITS",0) / t."GLANCE_VIEWS"
    END                                                 AS "CONVERSION_RATE",

    NVL(s."SHIPPED_UNITS",   0)                         AS "SHIPPED_UNITS",
    NVL(s."SHIPPED_REVENUE", 0)                         AS "SHIPPED_REVENUE",

    /* --- Profitability --- */
    n."AVG_NET_PPM",

    /* --- Inventory & operations --- */
    i."AVG_PROCURABLE_OOS",

    /* total on-hand units & value */
    NVL(i."SELLABLE_ON_HAND_UNITS",0)
      + NVL(i."UNSELLABLE_ON_HAND_UNITS",0)             AS "TOTAL_ON_HAND_UNITS",
    CASE
        WHEN NVL(s."TOTAL_ORDERED_UNITS",0) > 0 THEN
             ( NVL(i."SELLABLE_ON_HAND_UNITS",0)
             + NVL(i."UNSELLABLE_ON_HAND_UNITS",0) )
             * ( s."ORDERED_REVENUE" / s."TOTAL_ORDERED_UNITS" )
    END                                                 AS "ON_HAND_VALUE",

    /* net received */
    i."NET_RECEIVED_UNITS",
    i."NET_RECEIVED_VALUE",

    /* purchase-order / order-fill metrics */
    i."OPEN_PURCHASE_ORDER_QUANTITY",
    i."UNFILLED_CUSTOMER_ORDERED_UNITS",
    i."VENDOR_CONFIRMATION_RATE",
    i."RECEIVE_FILL_RATE",
    i."SELL_THROUGH_RATE",
    i."OVERALL_VENDOR_LEAD_TIME_DAYS"

FROM        sales      s
FULL JOIN   traffic    t  USING ("DATE","ASIN")
FULL JOIN   inventory  i  USING ("DATE","ASIN")
FULL JOIN   netppm     n  USING ("DATE","ASIN")

ORDER BY "DATE", "ASIN";