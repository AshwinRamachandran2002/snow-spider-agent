WITH daily_sales AS (
  SELECT
    DATEDIFF('day', '2017-01-01', DATE("orders"."order_purchase_timestamp")) AS "day_number",
    SUM("order_items"."price") AS "total_sales"
  FROM E_COMMERCE.E_COMMERCE."ORDER_ITEMS" AS "order_items"
  JOIN E_COMMERCE.E_COMMERCE."ORDERS" AS "orders"
    ON "order_items"."order_id" = "orders"."order_id"
  JOIN E_COMMERCE.E_COMMERCE."PRODUCTS" AS "products"
    ON "order_items"."product_id" = "products"."product_id"
  WHERE "products"."product_category_name" = 'brinquedos'
    AND DATE("orders"."order_purchase_timestamp") >= '2017-01-01'
    AND DATE("orders"."order_purchase_timestamp") <= '2018-08-29'
  GROUP BY DATEDIFF('day', '2017-01-01', DATE("orders"."order_purchase_timestamp"))
),
regression_coefficients AS (
  SELECT
    REGR_SLOPE("total_sales", "day_number") AS "slope",
    REGR_INTERCEPT("total_sales", "day_number") AS "intercept"
  FROM daily_sales
),
numbers AS (
  SELECT ROW_NUMBER() OVER (ORDER BY NULL) - 1 AS n
  FROM E_COMMERCE.E_COMMERCE."ORDER_ITEMS"
  LIMIT 8
),
predicted_dates AS (
  SELECT
    DATEADD('day', n, '2018-12-03') AS "date",
    DATEDIFF('day', '2017-01-01', DATEADD('day', n, '2018-12-03')) AS "day_number"
  FROM numbers
),
predictions AS (
  SELECT
    pd."date",
    rc."slope" * pd."day_number" + rc."intercept" AS "predicted_sales"
  FROM predicted_dates pd CROSS JOIN regression_coefficients rc
),
moving_averages AS (
  SELECT
    TO_VARCHAR(p1."date", 'YYYY-MM-DD') AS "Date",
    ROUND(AVG(p2."predicted_sales"), 4) AS "5-Day Symmetric Moving Average"
  FROM predictions p1
  JOIN predictions p2
    ON p2."date" BETWEEN DATEADD('day', -2, p1."date") AND DATEADD('day', 2, p1."date")
  WHERE p1."date" BETWEEN '2018-12-05' AND '2018-12-08'
  GROUP BY p1."date"
),
final_output AS (
  SELECT "Date", "5-Day Symmetric Moving Average" FROM moving_averages
  UNION ALL
  SELECT 'Total Sum' AS "Date", ROUND(SUM("5-Day Symmetric Moving Average"), 4) AS "5-Day Symmetric Moving Average" FROM moving_averages
)
SELECT * FROM final_output ORDER BY "Date";