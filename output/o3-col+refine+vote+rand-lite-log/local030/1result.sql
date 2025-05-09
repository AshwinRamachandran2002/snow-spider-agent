SELECT AVG(city_stats.total_payments)        AS avg_of_city_totals,
       AVG(city_stats.delivered_order_count) AS avg_of_city_order_counts
FROM (
    /* ❶ Sum every order’s payments */
    SELECT c."customer_city",
           SUM(op."order_payment_total") AS total_payments,
           COUNT(*)                     AS delivered_order_count
    FROM (
        SELECT "order_id",
               SUM("payment_value") AS "order_payment_total"
        FROM   "olist_order_payments"
        GROUP  BY "order_id"
    )                AS op
    JOIN "olist_orders"    AS o ON op."order_id"   = o."order_id"
    JOIN "olist_customers" AS c ON o."customer_id" = c."customer_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY c."customer_city"
    ORDER BY total_payments ASC
    LIMIT 5
) AS city_stats;