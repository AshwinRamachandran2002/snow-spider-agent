/*  Daily 30‑day manufacturing view product‑level report (08‑Jan‑2022 – 06‑Feb‑2022)  */
WITH sales AS (
    SELECT
        CAST("DATE" AS DATE)                             AS "DATE",
        "ASIN",
        MAX("PROGRAM")                                   AS "PROGRAM",
        MAX("PERIOD")                                    AS "PERIOD",
        MAX("DISTRIBUTOR_VIEW")                          AS "DISTRIBUTOR_VIEW",
        SUM("ORDERED_UNITS")                             AS "TOTAL_ORDERED_UNITS",
        SUM("ORDERED_REVENUE")                           AS "ORDERED_REVENUE",
        SUM("SHIPPED_UNITS")                             AS "SHIPPED_UNITS",
        SUM("SHIPPED_REVENUE")                           AS "SHIPPED_REVENUE"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES"
    WHERE "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
      AND "PERIOD"           = 'DAILY'
      AND "PROGRAM"          = 'Amazon Retail'
      AND "DISTRIBUTOR_VIEW" = 'Manufacturing'
    GROUP BY CAST("DATE" AS DATE), "ASIN"
),
traffic AS (
    SELECT
        CAST("DATE" AS DATE)  AS "DATE",
        "ASIN",
        SUM("GLANCE_VIEWS")   AS "GLANCE_VIEWS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC"
    WHERE "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
      AND "PERIOD"           = 'DAILY'
      AND "PROGRAM"          = 'Amazon Retail'
      AND "DISTRIBUTOR_VIEW" = 'Manufacturing'
    GROUP BY CAST("DATE" AS DATE), "ASIN"
),
inventory AS (
    SELECT
        CAST("DATE" AS DATE)                                     AS "DATE",
        "ASIN",
        AVG("PROCURABLE_PRODUCT_OOS")                            AS "AVG_PROCURABLE_PRODUCT_OOS",
        SUM("SELLABLE_ON_HAND_UNITS")                            AS "TOTAL_ONHAND_UNITS",
        SUM("SELLABLE_ON_HAND_INVENTORY")                        AS "TOTAL_ONHAND_VALUE",
        SUM("NET_RECEIVED_UNITS")                                AS "NET_RECEIVED_UNITS",
        SUM("NET_RECEIVED")                                      AS "NET_RECEIVED_VALUE",
        SUM("OPEN_PURCHASE_ORDER_QUANTITY")                      AS "OPEN_PO_QTY",
        SUM("UNFILLED_CUSTOMER_ORDERED_UNITS")                   AS "UNFILLED_CUSTOMER_ORDERED_UNITS",
        AVG("VENDOR_CONFIRMATION_RATE")                          AS "AVG_VENDOR_CONFIRMATION_RATE",
        AVG("RECEIVE_FILL_RATE")                                 AS "AVG_RECEIVE_FILL_RATE",
        AVG("SELL_THROUGH_RATE")                                 AS "AVG_SELL_THROUGH_RATE",
        AVG("OVERALL_VENDOR_LEAD_TIME_DAYS")                     AS "AVG_VENDOR_LEAD_TIME"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY"
    WHERE "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
      AND "PERIOD"           = 'DAILY'
      AND "PROGRAM"          = 'Amazon Retail'
      AND "DISTRIBUTOR_VIEW" = 'Manufacturing'
    GROUP BY CAST("DATE" AS DATE), "ASIN"
),
netppm AS (
    SELECT
        CAST("DATE" AS DATE) AS "DATE",
        "ASIN",
        AVG("NET_PPM")       AS "AVG_NET_PPM"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_NET_PPM"
    WHERE "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
      AND "PERIOD"           = 'DAILY'
      AND "PROGRAM"          = 'Amazon Retail'
      AND "DISTRIBUTOR_VIEW" = 'Manufacturing'
    GROUP BY CAST("DATE" AS DATE), "ASIN"
)
SELECT
    s."DATE"                                            AS "date",
    s."ASIN"                                            AS "asin",
    s."PROGRAM"                                         AS "program",
    s."PERIOD"                                          AS "period",
    s."DISTRIBUTOR_VIEW"                                AS "distributor_view",
    s."TOTAL_ORDERED_UNITS"                             AS "total_ordered_units",
    s."ORDERED_REVENUE"                                 AS "ordered_revenue",
    ROUND(
        CASE WHEN s."TOTAL_ORDERED_UNITS" <> 0
             THEN s."ORDERED_REVENUE" / s."TOTAL_ORDERED_UNITS" END
    ,4)                                                 AS "avg_selling_price",
    t."GLANCE_VIEWS"                                    AS "glance_views",
    ROUND(
        CASE WHEN t."GLANCE_VIEWS" <> 0
             THEN s."TOTAL_ORDERED_UNITS" / t."GLANCE_VIEWS" END
    ,4)                                                 AS "conversion_rate",
    s."SHIPPED_UNITS"                                   AS "shipped_units",
    s."SHIPPED_REVENUE"                                 AS "shipped_revenue",
    ROUND(n."AVG_NET_PPM",4)                            AS "avg_net_ppm",
    ROUND(i."AVG_PROCURABLE_PRODUCT_OOS",4)             AS "avg_procurable_product_oos",
    i."TOTAL_ONHAND_UNITS"                              AS "total_onhand_units",
    i."TOTAL_ONHAND_VALUE"                              AS "total_onhand_value",
    i."NET_RECEIVED_UNITS"                              AS "net_received_units",
    i."NET_RECEIVED_VALUE"                              AS "net_received_value",
    i."OPEN_PO_QTY"                                     AS "open_po_qty",
    i."UNFILLED_CUSTOMER_ORDERED_UNITS"                 AS "unfilled_customer_ordered_units",
    ROUND(i."AVG_VENDOR_CONFIRMATION_RATE",4)           AS "avg_vendor_confirmation_rate",
    ROUND(i."AVG_RECEIVE_FILL_RATE",4)                  AS "avg_receive_fill_rate",
    ROUND(i."AVG_SELL_THROUGH_RATE",4)                  AS "avg_sell_through_rate",
    ROUND(i."AVG_VENDOR_LEAD_TIME",4)                   AS "avg_vendor_lead_time"
FROM sales s
LEFT JOIN traffic   t ON t."DATE" = s."DATE" AND t."ASIN" = s."ASIN"
LEFT JOIN inventory i ON i."DATE" = s."DATE" AND i."ASIN" = s."ASIN"
LEFT JOIN netppm    n ON n."DATE" = s."DATE" AND n."ASIN" = s."ASIN"
ORDER BY s."DATE", s."ASIN";