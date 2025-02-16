-- Task: Could you generate a report that shows the number of delivered orders for each year in 2016, 2017, and 2018?
SELECT
  "Year" AS "year",
  COUNT(*) AS "NumberOfDeliveredOrders"
FROM
(
  SELECT 
    TO_VARCHAR(TO_DATE("order_delivered_customer_date"), 'YYYY') AS "Year"
  FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
  WHERE "order_status" = 'delivered'
    AND "order_delivered_customer_date" IS NOT NULL
    AND "order_delivered_customer_date" <> ''
    AND TO_VARCHAR(TO_DATE("order_delivered_customer_date"), 'YYYY') IN ('2016', '2017', '2018')
) A
GROUP BY "Year"
ORDER BY "Year" ASC;