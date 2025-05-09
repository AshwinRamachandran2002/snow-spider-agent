WITH daily_sales AS (
  SELECT
    DATE("orders"."order_purchase_timestamp") AS sale_date,
    COUNT(*) AS toys_sold
  FROM "orders"
  JOIN "order_items" ON "orders"."order_id" = "order_items"."order_id"
  JOIN "products" ON "order_items"."product_id" = "products"."product_id"
  JOIN "product_category_name_translation" ON "products"."product_category_name" = "product_category_name_translation"."product_category_name"
  WHERE "product_category_name_translation"."product_category_name_english" = 'toys'
    AND DATE("orders"."order_purchase_timestamp") BETWEEN '2017-01-01' AND '2018-08-29'
  GROUP BY sale_date
),
daily_sales_with_x AS (
  SELECT
    sale_date,
    CAST(julianday(sale_date) - julianday('2017-01-01') AS INTEGER) AS x,
    toys_sold AS y
  FROM daily_sales
),
stats AS (
  SELECT
    COUNT(*) AS N,
    SUM(x) AS sum_x,
    SUM(x * x) AS sum_x2,
    SUM(y) AS sum_y,
    SUM(x * y) AS sum_xy
  FROM daily_sales_with_x
),
regression AS (
  SELECT
    ((N * sum_xy - sum_x * sum_y) / (N * sum_x2 - sum_x * sum_x)) AS b,
    (sum_y - ((N * sum_xy - sum_x * sum_y) / (N * sum_x2 - sum_x * sum_x)) * sum_x) / N AS a
  FROM stats
),
all_dates AS (
  WITH RECURSIVE dates(date) AS (
    SELECT DATE('2017-01-01')
    UNION ALL
    SELECT DATE(date, '+1 day')
    FROM dates
    WHERE date < '2018-12-10'
  )
  SELECT date FROM dates
),
predictions AS (
  SELECT
    date AS sale_date,
    CAST(julianday(date) - julianday('2017-01-01') AS INTEGER) AS x,
    (SELECT a FROM regression) + (SELECT b FROM regression) * (CAST(julianday(date) - julianday('2017-01-01') AS INTEGER)) AS predicted_y
  FROM all_dates
),
moving_avg AS (
  SELECT
    p1.sale_date,
    AVG(p2.predicted_y) AS moving_average
  FROM predictions p1
  JOIN predictions p2 ON p2.sale_date BETWEEN DATE(p1.sale_date, '-2 day') AND DATE(p1.sale_date, '+2 day')
  WHERE p1.sale_date BETWEEN '2018-12-05' AND '2018-12-08'
  GROUP BY p1.sale_date
),
result AS (
  SELECT
    SUM(moving_average) AS Total_Moving_Average
  FROM moving_avg
)
SELECT
  Total_Moving_Average
FROM result;