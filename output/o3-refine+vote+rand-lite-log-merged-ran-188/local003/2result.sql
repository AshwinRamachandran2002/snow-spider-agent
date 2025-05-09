WITH delivered_orders AS (
    SELECT
        o."order_id",
        c."customer_unique_id",
        o."order_purchase_timestamp"
    FROM "orders"  o
    JOIN "customers" c
          ON c."customer_id" = o."customer_id"
    WHERE o."order_status" = 'delivered'
),
order_values AS (
    SELECT
        op."order_id",
        SUM(op."payment_value") AS "order_total_value"
    FROM "order_payments" op
    GROUP BY op."order_id"
),
customer_rfm AS (
    SELECT
        d."customer_unique_id",
        MAX(d."order_purchase_timestamp")                AS "last_purchase_ts",
        COUNT(*)                                          AS "freq_orders",
        SUM(ov."order_total_value")                       AS "monetary_total"
    FROM delivered_orders d
    JOIN order_values   ov ON ov."order_id" = d."order_id"
    GROUP BY d."customer_unique_id"
),
customer_rfm_scored AS (
    SELECT
        cr."customer_unique_id",
        cr."last_purchase_ts",
        cr."freq_orders",
        cr."monetary_total",
        CASE
             WHEN julianday('now') - julianday(cr."last_purchase_ts") <= 90 THEN 'R_Recent'
             ELSE 'R_Old'
        END                                              AS "R_Score",
        CASE
             WHEN cr."freq_orders" >= 3 THEN 'F_High'
             ELSE 'F_Low'
        END                                              AS "F_Score",
        CASE
             WHEN cr."monetary_total" >= 500 THEN 'M_High'
             ELSE 'M_Low'
        END                                              AS "M_Score",
        ROUND(cr."monetary_total" * 1.0 / cr."freq_orders",4) AS "avg_sales_per_order"
    FROM customer_rfm cr
)
SELECT
    ("R_Score" || '-' || "F_Score" || '-' || "M_Score") AS "RFM_segment",
    ROUND(AVG("avg_sales_per_order"),4)                 AS "segment_avg_sales",
    COUNT(*)                                            AS "customers_in_segment"
FROM customer_rfm_scored
GROUP BY "RFM_segment"
ORDER BY "segment_avg_sales" DESC;