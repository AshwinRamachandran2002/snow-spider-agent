SELECT MAX(Monthly_Orders) AS Highest_Monthly_Delivered_Orders_Volume
FROM (
    SELECT COUNT("order_id") AS Monthly_Orders
    FROM "olist_orders"
    WHERE "order_status" = 'delivered'
      AND strftime('%Y', "order_delivered_customer_date") = (
          SELECT strftime('%Y', "order_delivered_customer_date") AS "Year"
          FROM "olist_orders"
          WHERE "order_status" = 'delivered'
            AND strftime('%Y', "order_delivered_customer_date") IN ('2016', '2017', '2018')
            AND "order_delivered_customer_date" IS NOT NULL
          GROUP BY "Year"
          ORDER BY COUNT("order_id") ASC
          LIMIT 1
      )
      AND "order_delivered_customer_date" IS NOT NULL
    GROUP BY strftime('%Y-%m', "order_delivered_customer_date")
);