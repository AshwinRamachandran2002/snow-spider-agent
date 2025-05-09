WITH city_stats AS (
    SELECT
        c."customer_city",
        SUM(op."payment_value")          AS total_payments,
        COUNT(DISTINCT o."order_id")     AS delivered_orders
    FROM   "olist_orders"          AS o
    JOIN   "olist_customers"       AS c   ON o."customer_id" = c."customer_id"
    JOIN   "olist_order_payments"  AS op  ON o."order_id"     = op."order_id"
    WHERE  o."order_status" = 'delivered'
    GROUP BY c."customer_city"
    ORDER BY total_payments ASC
    LIMIT 5
)
SELECT
    ROUND(AVG(total_payments), 4)   AS avg_total_payments,
    ROUND(AVG(delivered_orders), 4) AS avg_delivered_orders
FROM   city_stats;