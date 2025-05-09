SELECT AVG("city_payments") AS "average_total_payments",
       AVG("order_counts") AS "average_total_delivered_order_counts"
FROM (
    SELECT "c"."customer_city",
           SUM("op"."payment_value") AS "city_payments",
           COUNT(DISTINCT "o"."order_id") AS "order_counts"
    FROM "olist_orders" AS "o"
    JOIN "olist_customers" AS "c"
      ON "o"."customer_id" = "c"."customer_id"
    JOIN "olist_order_payments" AS "op"
      ON "o"."order_id" = "op"."order_id"
    WHERE "o"."order_status" = 'delivered'
    GROUP BY "c"."customer_city"
    ORDER BY "city_payments" ASC
    LIMIT 5
) AS "lowest_cities";