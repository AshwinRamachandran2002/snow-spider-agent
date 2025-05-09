WITH delivered_orders AS (
  SELECT "order_id",
         TRY_TO_DATE("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS') AS "delivered_date"
  FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"
  WHERE "order_status" = 'delivered' 
    AND "order_delivered_customer_date" IS NOT NULL 
    AND "order_delivered_customer_date" != ''
    AND TRY_TO_DATE("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS') IS NOT NULL
),
valid_delivered_orders AS (
  SELECT "order_id",
         "delivered_date",
         EXTRACT(YEAR FROM "delivered_date") AS "year_delivered"
  FROM delivered_orders
  WHERE EXTRACT(YEAR FROM "delivered_date") IN (2016, 2017, 2018)
),
annual_orders AS (
  SELECT "year_delivered", COUNT("order_id") AS "annual_orders"
  FROM valid_delivered_orders
  GROUP BY "year_delivered"
),
min_year AS (
  SELECT "year_delivered"
  FROM annual_orders
  WHERE "annual_orders" = (SELECT MIN("annual_orders") FROM annual_orders)
),
monthly_orders AS (
  SELECT COUNT("order_id") AS "Highest_Monthly_Delivered_Orders_Volume",
         TRIM(TO_CHAR("delivered_date", 'Month')) AS "Month",
         "year_delivered" AS "Year"
  FROM valid_delivered_orders
  WHERE "year_delivered" = (SELECT "year_delivered" FROM min_year)
  GROUP BY TRIM(TO_CHAR("delivered_date", 'Month')), "year_delivered"
),
max_month AS (
  SELECT "Highest_Monthly_Delivered_Orders_Volume", "Month", "Year"
  FROM monthly_orders
  ORDER BY "Highest_Monthly_Delivered_Orders_Volume" DESC NULLS LAST
  LIMIT 1
)
SELECT "Highest_Monthly_Delivered_Orders_Volume", "Month", "Year"
FROM max_month;