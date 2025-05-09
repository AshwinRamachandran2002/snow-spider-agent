SELECT MAX("Delivered_Orders") AS "Highest_Monthly_Delivered_Orders_Volume"
FROM (
    SELECT SUBSTR("order_delivered_customer_date", 1, 7) AS "Year_Month",
           COUNT(*) AS "Delivered_Orders"
    FROM "olist_orders"
    WHERE "order_status" = 'delivered'
      AND "order_delivered_customer_date" IS NOT NULL
      AND SUBSTR("order_delivered_customer_date", 1, 4) = (
          SELECT "Year"
          FROM (
              SELECT SUBSTR("order_delivered_customer_date", 1, 4) AS "Year",
                     COUNT(*) AS "Total_Delivered_Orders"
              FROM "olist_orders"
              WHERE "order_status" = 'delivered'
                AND "order_delivered_customer_date" IS NOT NULL
                AND SUBSTR("order_delivered_customer_date", 1, 4) IN ('2016', '2017', '2018')
              GROUP BY "Year"
              ORDER BY "Total_Delivered_Orders" ASC
              LIMIT 1
          )
      )
    GROUP BY "Year_Month"
);