SELECT
  "Month Name",
  SUM(CASE WHEN "Year" = 2016 THEN "num_orders" ELSE 0 END) AS "2016",
  SUM(CASE WHEN "Year" = 2017 THEN "num_orders" ELSE 0 END) AS "2017",
  SUM(CASE WHEN "Year" = 2018 THEN "num_orders" ELSE 0 END) AS "2018"
FROM (
  SELECT
    EXTRACT(MONTH FROM TRY_TO_TIMESTAMP("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS')) AS "Month Number",
    TRIM(TO_CHAR(TRY_TO_TIMESTAMP("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS'), 'Month')) AS "Month Name",
    EXTRACT(YEAR FROM TRY_TO_TIMESTAMP("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS')) AS "Year",
    COUNT(*) AS "num_orders"
  FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
  WHERE "order_status" = 'delivered'
    AND "order_delivered_customer_date" IS NOT NULL
    AND TRY_TO_TIMESTAMP("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS') IS NOT NULL
  GROUP BY "Month Number", "Month Name", "Year"
) t
GROUP BY "Month Number", "Month Name"
ORDER BY "Month Number";