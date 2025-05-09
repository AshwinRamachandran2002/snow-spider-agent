WITH  sales AS (   /* daily sales ---------------------------------------------------------------- */
        SELECT  s."DATE",
                s."ASIN",
                s."ORDERED_UNITS",
                s."ORDERED_REVENUE",
                s."SHIPPED_UNITS",
                s."SHIPPED_REVENUE"
        FROM    AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES" s
        WHERE   s."PERIOD"          = 'DAILY'
          AND   s."PROGRAM"         = 'Amazon Retail'
          AND   s."DISTRIBUTOR_VIEW"= 'Manufacturing'
          AND   s."DATE" BETWEEN '2022-01-08' AND '2022-02-06'          /* 30‑day window */
),  traffic AS (   /* daily traffic --------------------------------------------------------------- */
        SELECT  t."DATE",
                t."ASIN",
                t."GLANCE_VIEWS"
        FROM    AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC" t
        WHERE   t."PERIOD"          = 'DAILY'
          AND   t."PROGRAM"         = 'Amazon Retail'
          AND   t."DISTRIBUTOR_VIEW"= 'Manufacturing'
          AND   t."DATE" BETWEEN '2022-01-08' AND '2022-02-06'
),  inventory AS ( /* daily inventory & supply chain ---------------------------------------------- */
        SELECT  i."DATE",
                i."ASIN",
                i."PROCURABLE_PRODUCT_OOS",
                i."SELLABLE_ON_HAND_UNITS",
                i."UNSELLABLE_ON_HAND_UNITS",
                i."SELLABLE_ON_HAND_INVENTORY",
                i."UNSELLABLE_ON_HAND_INVENTORY",
                i."NET_RECEIVED_UNITS",
                i."NET_RECEIVED",
                i."OPEN_PURCHASE_ORDER_QUANTITY",
                i."UNFILLED_CUSTOMER_ORDERED_UNITS",
                i."VENDOR_CONFIRMATION_RATE",
                i."RECEIVE_FILL_RATE",
                i."SELL_THROUGH_RATE",
                i."OVERALL_VENDOR_LEAD_TIME_DAYS"
        FROM    AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY" i
        WHERE   i."PERIOD"          = 'DAILY'
          AND   i."PROGRAM"         = 'Amazon Retail'
          AND   i."DISTRIBUTOR_VIEW"= 'Manufacturing'
          AND   i."DATE" BETWEEN '2022-01-08' AND '2022-02-06'
),  net_ppm AS (   /* daily profitability --------------------------------------------------------- */
        SELECT  n."DATE",
                n."ASIN",
                n."NET_PPM"
        FROM    AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_NET_PPM" n
        WHERE   n."PERIOD"          = 'DAILY'
          AND   n."PROGRAM"         = 'Amazon Retail'
          AND   n."DISTRIBUTOR_VIEW"= 'Manufacturing'
          AND   n."DATE" BETWEEN '2022-01-08' AND '2022-02-06'
)

/* final daily product‑level report --------------------------------------------------------------- */
SELECT  s."DATE",
        s."ASIN",

        /* sales metrics ------------------------------------------------------------------------- */
        s."ORDERED_UNITS"                                           AS "TOTAL_ORDERED_UNITS",
        s."ORDERED_REVENUE"                                         AS "ORDERED_REVENUE",
        ROUND( s."ORDERED_REVENUE" / NULLIF( s."ORDERED_UNITS",0),4 )          AS "AVG_SELLING_PRICE",

        /* traffic & conversion ------------------------------------------------------------------ */
        t."GLANCE_VIEWS",
        ROUND( s."ORDERED_UNITS" / NULLIF( t."GLANCE_VIEWS",0),4 )              AS "CONVERSION_RATE",

        /* shipment information ------------------------------------------------------------------ */
        s."SHIPPED_UNITS",
        s."SHIPPED_REVENUE",

        /* profitability ------------------------------------------------------------------------- */
        n."NET_PPM"                                                AS "AVG_NET_PPM",

        /* inventory & supply chain -------------------------------------------------------------- */
        i."PROCURABLE_PRODUCT_OOS"                                 AS "AVG_PROCURABLE_PRODUCT_OOS",
        ( i."SELLABLE_ON_HAND_UNITS" + i."UNSELLABLE_ON_HAND_UNITS")            AS "TOTAL_ON_HAND_UNITS",
        ( i."SELLABLE_ON_HAND_INVENTORY" + i."UNSELLABLE_ON_HAND_INVENTORY")    AS "TOTAL_ON_HAND_VALUE",
        i."NET_RECEIVED_UNITS",
        i."NET_RECEIVED"                                           AS "NET_RECEIVED_VALUE",
        i."OPEN_PURCHASE_ORDER_QUANTITY",
        i."UNFILLED_CUSTOMER_ORDERED_UNITS",
        i."VENDOR_CONFIRMATION_RATE"                               AS "AVG_VENDOR_CONFIRMATION_RATE",
        i."RECEIVE_FILL_RATE"                                      AS "AVG_RECEIVE_FILL_RATE",
        i."SELL_THROUGH_RATE"                                      AS "AVG_SELL_THROUGH_RATE",
        i."OVERALL_VENDOR_LEAD_TIME_DAYS"                          AS "AVG_VENDOR_LEAD_TIME_DAYS"

FROM        sales     s
LEFT JOIN   traffic   t ON t."DATE" = s."DATE" AND t."ASIN" = s."ASIN"
LEFT JOIN   inventory i ON i."DATE" = s."DATE" AND i."ASIN" = s."ASIN"
LEFT JOIN   net_ppm   n ON n."DATE" = s."DATE" AND n."ASIN" = s."ASIN"

ORDER BY    s."DATE" ,
            s."ASIN";