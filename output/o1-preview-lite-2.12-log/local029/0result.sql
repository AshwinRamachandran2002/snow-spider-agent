SELECT
    c."customer_unique_id",
    ROUND(AVG(p."payment_value"), 4) AS average_payment_value,
    c."customer_city" AS city,
    c."customer_state" AS state
FROM
    "olist_customers" c
    INNER JOIN "olist_orders" o ON c."customer_id" = o."customer_id"
    INNER JOIN "olist_order_payments" p ON o."order_id" = p."order_id"
WHERE
    o."order_status" = 'delivered'
GROUP BY
    c."customer_unique_id",
    c."customer_city",
    c."customer_state"
ORDER BY
    COUNT(*) DESC
LIMIT 3;