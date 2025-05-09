SELECT t."customer_city" AS City,
       t."average_payment" AS Average_Payment,
       t."order_count" AS Order_Count
FROM (
    SELECT c."customer_city",
           SUM(p."payment_value") AS "total_payments",
           AVG(p."payment_value") AS "average_payment",
           COUNT(DISTINCT o."order_id") AS "order_count"
        FROM "olist_orders" o
        JOIN "olist_order_payments" p ON o."order_id" = p."order_id"
        JOIN "olist_customers" c ON o."customer_id" = c."customer_id"
        WHERE o."order_status" = 'delivered'
        GROUP BY c."customer_city"
        ORDER BY "total_payments" ASC
        LIMIT 5
) t;