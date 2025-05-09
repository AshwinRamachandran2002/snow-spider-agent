SELECT MAX("orders_count") AS "Highest_Monthly_Delivered_Orders_Volume"
FROM (
    SELECT strftime('%m', "order_delivered_customer_date") AS "delivery_month",
           COUNT(*) AS "orders_count"
    FROM "olist_orders"
    WHERE "order_status" = 'delivered'
      AND strftime('%Y', "order_delivered_customer_date") = (
          SELECT strftime('%Y', "order_delivered_customer_date") AS "delivery_year"
          FROM "olist_orders"
          WHERE "order_status" = 'delivered'
            AND strftime('%Y', "order_delivered_customer_date") BETWEEN '2016' AND '2018'
            AND "order_delivered_customer_date" IS NOT NULL
            AND "order_delivered_customer_date" <> ''
          GROUP BY "delivery_year"
          ORDER BY COUNT(*) ASC
          LIMIT 1
      )
      AND "order_delivered_customer_date" IS NOT NULL
      AND "order_delivered_customer_date" <> ''
    GROUP BY "delivery_month"
);