WITH delivered_city_stats AS (
    SELECT
        c."customer_city",
        SUM(p."payment_value")               AS total_payments,
        COUNT(DISTINCT o."order_id")         AS delivered_orders
    FROM "olist_orders"          AS o
    JOIN "olist_order_payments"  AS p ON p."order_id" = o."order_id"
    JOIN "olist_customers"       AS c ON c."customer_id" = o."customer_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY c."customer_city"
),
bottom_five AS (
    SELECT *
    FROM delivered_city_stats
    ORDER BY total_payments ASC
    LIMIT 5
)
SELECT
    printf('%.4f', AVG(total_payments))    AS avg_total_payment,
    printf('%.4f', AVG(delivered_orders))  AS avg_total_delivered_order_count
FROM bottom_five;