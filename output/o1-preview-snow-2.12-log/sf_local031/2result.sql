WITH annual_delivered_orders AS (
    SELECT YEAR(TO_TIMESTAMP("order_purchase_timestamp")) AS "year",
           COUNT(*) AS "annual_delivered_orders_volume"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE "order_status" = 'delivered' AND
          YEAR(TO_TIMESTAMP("order_purchase_timestamp")) IN (2016, 2017, 2018)
    GROUP BY "year"
),
lowest_year AS (
    SELECT "year"
    FROM annual_delivered_orders
    ORDER BY "annual_delivered_orders_volume" ASC
    LIMIT 1
),
monthly_delivered_orders AS (
    SELECT YEAR(TO_TIMESTAMP("order_purchase_timestamp")) AS "year",
           MONTH(TO_TIMESTAMP("order_purchase_timestamp")) AS "month_number",
           TO_VARCHAR(TO_TIMESTAMP("order_purchase_timestamp"), 'MMMM') AS "month_name",
           COUNT(*) AS "monthly_delivered_orders_volume"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE "order_status" = 'delivered' AND
          YEAR(TO_TIMESTAMP("order_purchase_timestamp")) = (SELECT "year" FROM lowest_year)
    GROUP BY "year", "month_number", "month_name"
),
max_month AS (
    SELECT "monthly_delivered_orders_volume", "month_name", "year"
    FROM monthly_delivered_orders
    ORDER BY "monthly_delivered_orders_volume" DESC NULLS LAST
    LIMIT 1
)
SELECT "monthly_delivered_orders_volume" AS "Highest_Monthly_Delivered_Orders_Volume",
       "month_name" AS "Month",
       "year" AS "Year"
FROM max_month;