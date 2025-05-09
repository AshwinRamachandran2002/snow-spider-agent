/*  Daily manufacturing-view sales report : 08-Jan-2022 → 06-Feb-2022  */
WITH base AS (   ------------------------------------------------------------------
    SELECT
        s."DATE",
        s."ASIN",

        /* demand & fulfilment */
        s."ORDERED_UNITS",
        s."ORDERED_REVENUE",
        s."SHIPPED_UNITS",
        s."SHIPPED_REVENUE",
        t."GLANCE_VIEWS",

        /* inventory & supply-chain */
        i."SELLABLE_ON_HAND_UNITS",
        i."UNSELLABLE_ON_HAND_UNITS",
        i."OPEN_PURCHASE_ORDER_QUANTITY",
        i."UNFILLED_CUSTOMER_ORDERED_UNITS",
        i."PROCURABLE_PRODUCT_OOS",
        i."VENDOR_CONFIRMATION_RATE",
        i."RECEIVE_FILL_RATE",
        i."SELL_THROUGH_RATE",
        i."NET_RECEIVED_UNITS",
        i."OVERALL_VENDOR_LEAD_TIME_DAYS",

        /* profitability */
        n."NET_PPM"
    FROM   AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES"   s
    JOIN   AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC" t
           ON  s."DATE"            = t."DATE"
           AND s."ASIN"            = t."ASIN"
           AND s."PROGRAM"         = t."PROGRAM"
           AND s."PERIOD"          = t."PERIOD"
           AND s."DISTRIBUTOR_VIEW"= t."DISTRIBUTOR_VIEW"
    JOIN   AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY" i
           ON  s."DATE" = i."DATE"
           AND s."ASIN" = i."ASIN"
           AND i."DISTRIBUTOR_VIEW" = 'Manufacturing'
    LEFT  JOIN AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_NET_PPM" n
           ON  s."DATE" = n."DATE"
           AND s."ASIN" = n."ASIN"
           AND n."DISTRIBUTOR_VIEW" = 'Manufacturing'
    WHERE  s."DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND  s."PERIOD"          = 'DAILY'
      AND  s."DATE" BETWEEN '2022-01-08' AND '2022-02-06'
), agg AS (    ------------------------------------------------------------- roll-up
    SELECT
        "DATE",
        "ASIN",

        /* demand */
        SUM("ORDERED_UNITS")                          AS "TOTAL_ORDERED_UNITS",
        SUM("ORDERED_REVENUE")                        AS "ORDERED_REVENUE",
        CASE WHEN SUM("ORDERED_UNITS") = 0
             THEN NULL
             ELSE SUM("ORDERED_REVENUE") / SUM("ORDERED_UNITS") END
                                                     AS "AVG_SELLING_PRICE",
        SUM("GLANCE_VIEWS")                           AS "GLANCE_VIEWS",
        CASE WHEN SUM("GLANCE_VIEWS") = 0
             THEN NULL
             ELSE SUM("ORDERED_UNITS") / SUM("GLANCE_VIEWS") END
                                                     AS "CONVERSION_RATE",

        /* fulfilment */
        SUM("SHIPPED_UNITS")                          AS "SHIPPED_UNITS",
        SUM("SHIPPED_REVENUE")                        AS "SHIPPED_REVENUE",

        /* profitability & OOS */
        AVG("NET_PPM")                                AS "AVG_NET_PPM",
        AVG("PROCURABLE_PRODUCT_OOS")                 AS "AVG_PROCURABLE_PRODUCT_OOS",

        /* inventory positions */
        SUM("SELLABLE_ON_HAND_UNITS" + "UNSELLABLE_ON_HAND_UNITS")
                                                     AS "TOTAL_ON_HAND_UNITS",
        MAX("NET_RECEIVED_UNITS")                     AS "NET_RECEIVED_UNITS",

        /* PO & unfilled */
        AVG("OPEN_PURCHASE_ORDER_QUANTITY")           AS "OPEN_PURCHASE_ORDER_QUANTITY",
        AVG("UNFILLED_CUSTOMER_ORDERED_UNITS")        AS "UNFILLED_CUSTOMER_ORDERED_UNITS",

        /* supplier metrics */
        AVG("VENDOR_CONFIRMATION_RATE")               AS "AVG_VENDOR_CONFIRMATION_RATE",
        AVG("RECEIVE_FILL_RATE")                      AS "AVG_RECEIVE_FILL_RATE",
        AVG("SELL_THROUGH_RATE")                      AS "AVG_SELL_THROUGH_RATE",
        AVG("OVERALL_VENDOR_LEAD_TIME_DAYS")          AS "AVG_VENDOR_LEAD_TIME"
    FROM base
    GROUP BY "DATE", "ASIN"
)
SELECT
    "DATE",
    "ASIN",

    /* demand */
    "TOTAL_ORDERED_UNITS",
    "ORDERED_REVENUE",
    "AVG_SELLING_PRICE",
    "GLANCE_VIEWS",
    "CONVERSION_RATE",

    /* fulfilment */
    "SHIPPED_UNITS",
    "SHIPPED_REVENUE",

    /* profitability & OOS */
    "AVG_NET_PPM",
    "AVG_PROCURABLE_PRODUCT_OOS",

    /* inventory valuations */
    "TOTAL_ON_HAND_UNITS",
    ROUND("TOTAL_ON_HAND_UNITS" * "AVG_SELLING_PRICE", 4)  AS "ON_HAND_VALUE",
    "NET_RECEIVED_UNITS",
    ROUND("NET_RECEIVED_UNITS" * "AVG_SELLING_PRICE", 4)  AS "NET_RECEIVED_VALUE",

    /* PO & unfilled */
    "OPEN_PURCHASE_ORDER_QUANTITY",
    "UNFILLED_CUSTOMER_ORDERED_UNITS",

    /* supplier metrics */
    "AVG_VENDOR_CONFIRMATION_RATE",
    "AVG_RECEIVE_FILL_RATE",
    "AVG_SELL_THROUGH_RATE",
    "AVG_VENDOR_LEAD_TIME"
FROM   agg
ORDER  BY "DATE", "ASIN";