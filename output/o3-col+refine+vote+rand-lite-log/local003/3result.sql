WITH delivered_orders AS (
    SELECT *
    FROM "orders"
    WHERE "order_status" = 'delivered'
),
max_ts AS (
    SELECT MAX("order_purchase_timestamp") AS max_purchase_ts
    FROM delivered_orders
),
customer_rfm AS (
    /* R, F, M for each customer_unique_id */
    SELECT
        c."customer_unique_id",
        ROUND(julianday(mt.max_purchase_ts) - julianday(MAX(o."order_purchase_timestamp")), 1)   AS "recency_days",
        COUNT(DISTINCT o."order_id")                                                             AS "frequency_orders",
        SUM(op."payment_value")                                                                  AS "monetary_value"
    FROM delivered_orders o
    JOIN "customers"      c  ON o."customer_id" = c."customer_id"
    JOIN "order_payments" op ON o."order_id"    = op."order_id"
    CROSS JOIN max_ts     mt
    GROUP BY c."customer_unique_id"
),
customer_rfm_classified AS (
    /* bucketise each metric & compute average sales per order */
    SELECT
        "customer_unique_id",
        CASE
             WHEN "recency_days" <= 30 THEN 'R_Recent'
             WHEN "recency_days" <= 90 THEN 'R_Moderate'
             ELSE                           'R_Old'
        END                                                     AS "R_class",
        CASE
             WHEN "frequency_orders" >= 5 THEN 'F_Frequent'
             WHEN "frequency_orders" >= 3 THEN 'F_Medium'
             ELSE                          'F_Rare'
        END                                                     AS "F_class",
        CASE
             WHEN "monetary_value" * 1.0 / "frequency_orders" >= 150 THEN 'M_High'
             WHEN "monetary_value" * 1.0 / "frequency_orders" >= 75  THEN 'M_Medium'
             ELSE                                                         'M_Low'
        END                                                     AS "M_class",
        "monetary_value" * 1.0 / "frequency_orders"             AS "avg_sales_per_order"
    FROM customer_rfm
),
segment_comparison AS (
    /* aggregate by RFM segment */
    SELECT
        "R_class" || '_' || "F_class" || '_' || "M_class"        AS "RFM_segment",
        COUNT(DISTINCT "customer_unique_id")                     AS "num_customers",
        ROUND(AVG("avg_sales_per_order"), 4)                     AS "avg_sales_per_order_segment"
    FROM customer_rfm_classified
    GROUP BY "RFM_segment"
)
SELECT *
FROM segment_comparison
ORDER BY "avg_sales_per_order_segment" DESC;