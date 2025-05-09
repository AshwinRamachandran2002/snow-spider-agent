WITH city_totals AS (
    SELECT
        c."customer_city"                    AS city,
        SUM(p."payment_value")               AS total_payment,
        COUNT(DISTINCT o."order_id")         AS delivered_orders
    FROM   "olist_orders"           AS o
    JOIN   "olist_customers"        AS c ON c."customer_id" = o."customer_id"
    JOIN   "olist_order_payments"   AS p ON p."order_id" = o."order_id"
    WHERE  o."order_status" = 'delivered'
    GROUP BY c."customer_city"
    ORDER BY total_payment ASC, city ASC  -- secondary sort for determinism
    LIMIT 5
)
SELECT
    ROUND(AVG(total_payment), 4)    AS avg_of_total_payments,
    ROUND(AVG(delivered_orders), 4) AS avg_of_order_counts
FROM city_totals;