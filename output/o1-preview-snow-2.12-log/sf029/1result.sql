SELECT
    s."DATE" AS "date",
    s."ASIN",
    s."PROGRAM" AS "program",
    s."PERIOD" AS "period",
    s."DISTRIBUTOR_VIEW" AS "distributor_view",
    s."ORDERED_UNITS" AS "total_ordered_units",
    s."ORDERED_REVENUE" AS "ordered_revenue",
    ROUND(CASE WHEN s."ORDERED_UNITS" != 0 THEN s."ORDERED_REVENUE" / s."ORDERED_UNITS" ELSE NULL END, 4) AS "average_selling_price",
    t."GLANCE_VIEWS" AS "glance_views",
    ROUND(CASE WHEN t."GLANCE_VIEWS" != 0 THEN s."ORDERED_UNITS" / t."GLANCE_VIEWS" ELSE NULL END, 4) AS "conversion_rate",
    s."SHIPPED_UNITS" AS "shipped_units",
    s."SHIPPED_REVENUE" AS "shipped_revenue",
    n."NET_PPM" AS "average_net_ppm",
    i."PROCURABLE_PRODUCT_OOS" AS "average_procurable_product_oos",
    i."SELLABLE_ON_HAND_UNITS" AS "total_on_hand_units",
    i."SELLABLE_ON_HAND_INVENTORY" AS "total_on_hand_value",
    i."NET_RECEIVED_UNITS" AS "net_received_units",
    i."NET_RECEIVED" AS "net_received_value",
    i."OPEN_PURCHASE_ORDER_QUANTITY" AS "open_purchase_order_quantities",
    i."UNFILLED_CUSTOMER_ORDERED_UNITS" AS "unfilled_customer_ordered_units",
    i."VENDOR_CONFIRMATION_RATE" AS "average_vendor_confirmation_rate",
    i."RECEIVE_FILL_RATE" AS "receive_fill_rate",
    i."SELL_THROUGH_RATE" AS "sell_through_rate",
    i."OVERALL_VENDOR_LEAD_TIME_DAYS" AS "vendor_lead_time"
FROM
    "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_SALES" s
LEFT JOIN
    "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_TRAFFIC" t
    ON s."DATE" = t."DATE" AND s."ASIN" = t."ASIN" AND s."DISTRIBUTOR_VIEW" = t."DISTRIBUTOR_VIEW"
LEFT JOIN
    "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_INVENTORY" i
    ON s."DATE" = i."DATE" AND s."ASIN" = i."ASIN" AND s."DISTRIBUTOR_VIEW" = i."DISTRIBUTOR_VIEW"
LEFT JOIN
    "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_NET_PPM" n
    ON s."DATE" = n."DATE" AND s."ASIN" = n."ASIN" AND s."DISTRIBUTOR_VIEW" = n."DISTRIBUTOR_VIEW"
WHERE
    s."DATE" BETWEEN '2022-01-07' AND '2022-02-06' AND s."DISTRIBUTOR_VIEW" = 'Manufacturing'
ORDER BY
    s."DATE", s."ASIN";