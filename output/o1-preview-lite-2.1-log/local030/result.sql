WITH total_payments_per_order AS (
    SELECT o."order_id", c."customer_city", SUM(p."payment_value") AS total_payment_per_order
    FROM "olist_orders" o
    JOIN "olist_order_payments" p ON o."order_id" = p."order_id"
    JOIN "olist_customers" c ON o."customer_id" = c."customer_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY o."order_id", c."customer_city"
)

SELECT t."customer_city" AS City,
       ROUND(AVG(t."total_payment_per_order"), 4) AS Average_Payment,
       COUNT(*) AS Order_Count
FROM total_payments_per_order t
GROUP BY t."customer_city"
ORDER BY SUM(t."total_payment_per_order") ASC
LIMIT 5;