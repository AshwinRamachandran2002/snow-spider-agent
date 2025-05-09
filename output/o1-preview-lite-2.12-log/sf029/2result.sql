SELECT
    s."DATE" AS "date",
    s."ASIN",
    s."PROGRAM" AS "program",
    s."PERIOD" AS "period",
    s."DISTRIBUTOR_VIEW" AS "distributor_view",
    SUM(s."ORDERED_UNITS") AS "total_ordered_units",
    SUM(s."ORDERED_REVENUE") AS "ordered_revenue",
    ROUND(SUM(s."ORDERED_REVENUE") / NULLIF(SUM(s."ORDERED_UNITS"), 0), 4) AS "average_selling_price",
    SUM(t."GLANCE_VIEWS") AS "glance_views",
    ROUND(SUM(s."ORDERED_UNITS") / NULLIF(SUM(t."GLANCE_VIEWS"), 0), 4) AS "conversion_rate",
    SUM(s."SHIPPED_UNITS") AS "shipped_units",
    SUM(s."SHIPPED_REVENUE") AS "shipped_revenue",
    ROUND(AVG(n."NET_PPM"), 4) AS "average_net_ppm",
    ROUND(AVG(i."PROCURABLE_PRODUCT_OOS"), 4) AS "average_procurable_product_oos",
    ROUND(AVG(i."SELLABLE_ON_HAND_UNITS"), 4) AS "total_on_hand_units",
    ROUND(AVG(i."SELLABLE_ON_HAND_INVENTORY"), 4) AS "total_on_hand_value",
    SUM(i."NET_RECEIVED_UNITS") AS "net_received_units",
    SUM(i."NET_RECEIVED") AS "net_received_value",
    SUM(i."OPEN_PURCHASE_ORDER_QUANTITY") AS "open_purchase_order_quantities",
    SUM(i."UNFILLED_CUSTOMER_ORDERED_UNITS") AS "unfilled_customer_ordered_units",
    ROUND(AVG(i."VENDOR_CONFIRMATION_RATE"), 4) AS "average_vendor_confirmation_rate",
    ROUND(AVG(i."RECEIVE_FILL_RATE"), 4) AS "receive_fill_rate",
    ROUND(AVG(i."SELL_THROUGH_RATE"), 4) AS "sell_through_rate",
    ROUND(AVG(i."OVERALL_VENDOR_LEAD_TIME_DAYS"), 4) AS "vendor_lead_time"
FROM
    "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_SALES" s
LEFT JOIN
    "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_TRAFFIC" t
    ON s."DATE" = t."DATE" AND
       s."ASIN" = t."ASIN" AND
       s."DISTRIBUTOR_VIEW" = t."DISTRIBUTOR_VIEW"
LEFT JOIN
    "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_INVENTORY" i
    ON s."DATE" = i."DATE" AND
       s."ASIN" = i."ASIN" AND
       s."DISTRIBUTOR_VIEW" = i."DISTRIBUTOR_VIEW"
LEFT JOIN
    "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_NET_PPM" n
    ON s."DATE" = n."DATE" AND
       s."ASIN" = n."ASIN" AND
       s."DISTRIBUTOR_VIEW" = n."DISTRIBUTOR_VIEW"
WHERE
    s."DATE" BETWEEN '2022-01-07' AND '2022-02-06' AND
    s."DISTRIBUTOR_VIEW" = 'Manufacturing'
GROUP BY
    s."DATE",
    s."ASIN",
    s."PROGRAM",
    s."PERIOD",
    s."DISTRIBUTOR_VIEW"
ORDER BY
    s."DATE",
    s."ASIN";