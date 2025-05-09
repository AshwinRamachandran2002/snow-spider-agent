WITH sales AS (
    SELECT
        "DATE",
        "ASIN",
        "PROGRAM",
        "PERIOD",
        "DISTRIBUTOR_VIEW",
        "ORDERED_UNITS",
        "ORDERED_REVENUE",
        "SHIPPED_UNITS",
        "SHIPPED_REVENUE"
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_SALES"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "PROGRAM"         = 'Amazon Retail'
      AND "PERIOD"          = 'DAILY'
      AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
),
traffic AS (
    SELECT
        "DATE",
        "ASIN",
        "PROGRAM",
        "PERIOD",
        "DISTRIBUTOR_VIEW",
        "GLANCE_VIEWS"
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_TRAFFIC"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "PROGRAM"         = 'Amazon Retail'
      AND "PERIOD"          = 'DAILY'
      AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
),
inventory AS (
    SELECT
        "DATE",
        "ASIN",
        "PROGRAM",
        "PERIOD",
        "DISTRIBUTOR_VIEW",
        "PROCURABLE_PRODUCT_OOS",
        "SELLABLE_ON_HAND_UNITS",
        "SELLABLE_ON_HAND_INVENTORY",
        "NET_RECEIVED_UNITS",
        "NET_RECEIVED",
        "OPEN_PURCHASE_ORDER_QUANTITY",
        "UNFILLED_CUSTOMER_ORDERED_UNITS",
        "VENDOR_CONFIRMATION_RATE",
        "RECEIVE_FILL_RATE",
        "SELL_THROUGH_RATE",
        "OVERALL_VENDOR_LEAD_TIME_DAYS"
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_INVENTORY"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "PROGRAM"         = 'Amazon Retail'
      AND "PERIOD"          = 'DAILY'
      AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
),
netppm AS (
    SELECT
        "DATE",
        "ASIN",
        "PROGRAM",
        "PERIOD",
        "DISTRIBUTOR_VIEW",
        "NET_PPM"
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_NET_PPM"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "PROGRAM"         = 'Amazon Retail'
      AND "PERIOD"          = 'DAILY'
      AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
)
SELECT
    s."DATE"                                             AS "date",
    s."ASIN"                                             AS "asin",
    s."PROGRAM"                                          AS "program",
    s."PERIOD"                                           AS "period",
    s."DISTRIBUTOR_VIEW"                                 AS "distributor_view",
    SUM(s."ORDERED_UNITS")                               AS "total_ordered_units",
    SUM(s."ORDERED_REVENUE")                             AS "ordered_revenue",
    CASE WHEN SUM(s."ORDERED_UNITS") <> 0
         THEN ROUND(SUM(s."ORDERED_REVENUE") / SUM(s."ORDERED_UNITS"), 4)
    END                                                  AS "avg_selling_price",
    COALESCE(SUM(t."GLANCE_VIEWS"), 0)                   AS "glance_views",
    CASE WHEN COALESCE(SUM(t."GLANCE_VIEWS"), 0) <> 0
         THEN ROUND(SUM(s."ORDERED_UNITS") / SUM(t."GLANCE_VIEWS"), 4)
    END                                                  AS "conversion_rate",
    SUM(s."SHIPPED_UNITS")                               AS "shipped_units",
    SUM(s."SHIPPED_REVENUE")                             AS "shipped_revenue",
    ROUND(AVG(n."NET_PPM"), 4)                           AS "avg_net_ppm",
    ROUND(AVG(i."PROCURABLE_PRODUCT_OOS"), 4)            AS "avg_procurable_product_oos",
    SUM(i."SELLABLE_ON_HAND_UNITS")                      AS "total_onhand_units",
    SUM(i."SELLABLE_ON_HAND_INVENTORY")                  AS "total_onhand_value",
    SUM(i."NET_RECEIVED_UNITS")                          AS "net_received_units",
    SUM(i."NET_RECEIVED")                                AS "net_received_value",
    SUM(i."OPEN_PURCHASE_ORDER_QUANTITY")                AS "open_po_qty",
    SUM(i."UNFILLED_CUSTOMER_ORDERED_UNITS")             AS "unfilled_customer_ordered_units",
    ROUND(AVG(i."VENDOR_CONFIRMATION_RATE"), 4)          AS "avg_vendor_confirmation_rate",
    ROUND(AVG(i."RECEIVE_FILL_RATE"), 4)                 AS "avg_receive_fill_rate",
    ROUND(AVG(i."SELL_THROUGH_RATE"), 4)                 AS "avg_sell_through_rate",
    ROUND(AVG(i."OVERALL_VENDOR_LEAD_TIME_DAYS"), 4)     AS "avg_vendor_lead_time"
FROM   sales s
LEFT JOIN traffic  t
       ON s."DATE"             = t."DATE"
      AND s."ASIN"             = t."ASIN"
      AND s."PROGRAM"          = t."PROGRAM"
      AND s."PERIOD"           = t."PERIOD"
      AND s."DISTRIBUTOR_VIEW" = t."DISTRIBUTOR_VIEW"
LEFT JOIN inventory i
       ON s."DATE"             = i."DATE"
      AND s."ASIN"             = i."ASIN"
      AND s."PROGRAM"          = i."PROGRAM"
      AND s."PERIOD"           = i."PERIOD"
      AND s."DISTRIBUTOR_VIEW" = i."DISTRIBUTOR_VIEW"
LEFT JOIN netppm   n
       ON s."DATE"             = n."DATE"
      AND s."ASIN"             = n."ASIN"
      AND s."PROGRAM"          = n."PROGRAM"
      AND s."PERIOD"           = n."PERIOD"
      AND s."DISTRIBUTOR_VIEW" = n."DISTRIBUTOR_VIEW"
GROUP BY
    s."DATE",
    s."ASIN",
    s."PROGRAM",
    s."PERIOD",
    s."DISTRIBUTOR_VIEW"
ORDER BY
    s."DATE",
    s."ASIN";