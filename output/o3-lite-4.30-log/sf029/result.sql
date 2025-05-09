/* Daily detailed sales report – 30‑day window ending 2022‑02‑06 */
WITH params AS (
    SELECT 
        TO_DATE('2022-01-08') AS start_dt,
        TO_DATE('2022-02-06') AS end_dt
),

/* 1. SALES */
sales_agg AS (
    SELECT 
        s."DATE", 
        s."ASIN",
        SUM(s."ORDERED_UNITS")   AS total_ordered_units,
        SUM(s."ORDERED_REVENUE") AS ordered_revenue,
        SUM(s."SHIPPED_UNITS")   AS shipped_units,
        SUM(s."SHIPPED_REVENUE") AS shipped_revenue
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_SALES" s
    JOIN params p
      ON s."DATE" BETWEEN p.start_dt AND p.end_dt
    WHERE s."PERIOD"           = 'DAILY'
      AND s."PROGRAM"          = 'Amazon Retail'
      AND s."DISTRIBUTOR_VIEW" = 'Manufacturing'
    GROUP BY s."DATE", s."ASIN"
),

/* 2. TRAFFIC */
traffic_agg AS (
    SELECT 
        t."DATE",
        t."ASIN",
        SUM(t."GLANCE_VIEWS") AS glance_views
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_TRAFFIC" t
    JOIN params p
      ON t."DATE" BETWEEN p.start_dt AND p.end_dt
    WHERE t."PERIOD"           = 'DAILY'
      AND t."PROGRAM"          = 'Amazon Retail'
      AND t."DISTRIBUTOR_VIEW" = 'Manufacturing'
    GROUP BY t."DATE", t."ASIN"
),

/* 3. INVENTORY */
inv_agg AS (
    SELECT
        i."DATE",
        i."ASIN",
        AVG(i."PROCURABLE_PRODUCT_OOS")                                               AS avg_procurable_product_oos,
        SUM(i."SELLABLE_ON_HAND_UNITS" + i."UNSELLABLE_ON_HAND_UNITS")                AS total_onhand_units,
        SUM(i."SELLABLE_ON_HAND_INVENTORY" + i."UNSELLABLE_ON_HAND_INVENTORY")        AS total_onhand_value,
        SUM(i."NET_RECEIVED_UNITS")                                                   AS net_received_units,
        SUM(i."NET_RECEIVED")                                                         AS net_received_value,
        SUM(i."OPEN_PURCHASE_ORDER_QUANTITY")                                         AS open_po_qty,
        SUM(i."UNFILLED_CUSTOMER_ORDERED_UNITS")                                      AS unfilled_customer_ordered_units,
        AVG(i."VENDOR_CONFIRMATION_RATE")                                             AS avg_vendor_confirmation_rate,
        AVG(i."RECEIVE_FILL_RATE")                                                    AS avg_receive_fill_rate,
        AVG(i."SELL_THROUGH_RATE")                                                    AS avg_sell_through_rate,
        AVG(i."OVERALL_VENDOR_LEAD_TIME_DAYS")                                        AS avg_vendor_lead_time
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_INVENTORY" i
    JOIN params p
      ON i."DATE" BETWEEN p.start_dt AND p.end_dt
    WHERE i."PERIOD"           = 'DAILY'
      AND i."PROGRAM"          = 'Amazon Retail'
      AND i."DISTRIBUTOR_VIEW" = 'Manufacturing'
    GROUP BY i."DATE", i."ASIN"
),

/* 4. NET PPM */
ppm_agg AS (
    SELECT 
        n."DATE",
        n."ASIN",
        AVG(n."NET_PPM") AS avg_net_ppm
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_NET_PPM" n
    JOIN params p
      ON n."DATE" BETWEEN p.start_dt AND p.end_dt
    WHERE n."PERIOD"           = 'DAILY'
      AND n."PROGRAM"          = 'Amazon Retail'
      AND n."DISTRIBUTOR_VIEW" = 'Manufacturing'
    GROUP BY n."DATE", n."ASIN"
)

/* 5. FINAL REPORT */
SELECT  
       s."DATE"                                            AS date,
       s."ASIN"                                            AS asin,
       'Amazon Retail'                                     AS program,
       'DAILY'                                             AS period,
       'Manufacturing'                                     AS distributor_view,
       s.total_ordered_units                               AS total_ordered_units,
       ROUND(s.ordered_revenue,4)                          AS ordered_revenue,
       ROUND(
           CASE WHEN s.total_ordered_units <> 0 
                THEN s.ordered_revenue / s.total_ordered_units 
           END ,4)                                         AS avg_selling_price,
       t.glance_views                                      AS glance_views,
       ROUND(
           CASE WHEN t.glance_views <> 0 
                THEN s.total_ordered_units / t.glance_views 
           END ,4)                                         AS conversion_rate,
       s.shipped_units                                     AS shipped_units,
       ROUND(s.shipped_revenue,4)                          AS shipped_revenue,
       ROUND(ppm.avg_net_ppm,4)                            AS avg_net_ppm,
       ROUND(inv.avg_procurable_product_oos,4)             AS avg_procurable_product_oos,
       inv.total_onhand_units                              AS total_onhand_units,
       ROUND(inv.total_onhand_value,4)                     AS total_onhand_value,
       inv.net_received_units                              AS net_received_units,
       ROUND(inv.net_received_value,4)                     AS net_received_value,
       inv.open_po_qty                                     AS open_po_qty,
       inv.unfilled_customer_ordered_units                 AS unfilled_customer_ordered_units,
       ROUND(inv.avg_vendor_confirmation_rate,4)           AS avg_vendor_confirmation_rate,
       ROUND(inv.avg_receive_fill_rate,4)                  AS avg_receive_fill_rate,
       ROUND(inv.avg_sell_through_rate,4)                  AS avg_sell_through_rate,
       ROUND(inv.avg_vendor_lead_time,4)                   AS avg_vendor_lead_time
FROM sales_agg s
LEFT JOIN traffic_agg t
       ON t."DATE" = s."DATE" AND t."ASIN" = s."ASIN"
LEFT JOIN inv_agg inv
       ON inv."DATE" = s."DATE" AND inv."ASIN" = s."ASIN"
LEFT JOIN ppm_agg ppm
       ON ppm."DATE" = s."DATE" AND ppm."ASIN" = s."ASIN"
ORDER BY s."DATE", s."ASIN";