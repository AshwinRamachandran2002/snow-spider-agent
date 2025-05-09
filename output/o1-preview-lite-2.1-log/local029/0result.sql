WITH customer_order_counts AS (
    SELECT c."customer_unique_id", c."customer_city", c."customer_state", COUNT(*) AS "delivered_orders"
    FROM "olist_orders" o
    INNER JOIN "olist_customers" c ON o."customer_id" = c."customer_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY c."customer_unique_id", c."customer_city", c."customer_state"
),
top_customers AS (
    SELECT "customer_unique_id", "customer_city", "customer_state"
    FROM customer_order_counts
    ORDER BY "delivered_orders" DESC, "customer_unique_id" ASC
    LIMIT 3
)
SELECT tc."customer_unique_id", ROUND(AVG(p."payment_value"), 4) AS "average_payment_value",
       tc."customer_city", tc."customer_state"
FROM "olist_orders" o
INNER JOIN "olist_order_payments" p ON o."order_id" = p."order_id"
INNER JOIN "olist_customers" c ON o."customer_id" = c."customer_id"
INNER JOIN top_customers tc ON c."customer_unique_id" = tc."customer_unique_id"
WHERE o."order_status" = 'delivered'
GROUP BY tc."customer_unique_id", tc."customer_city", tc."customer_state";