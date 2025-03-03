WITH daily_sales AS (
  SELECT
    DATE("orders"."order_purchase_timestamp") AS "order_date",
    SUM("order_items"."price") AS y,
    julianday(DATE("orders"."order_purchase_timestamp")) - julianday('2017-01-01') AS x
  FROM "orders"
  JOIN "order_items" ON "orders"."order_id" = "order_items"."order_id"
  WHERE "order_items"."product_id" IN (
      SELECT "product_id"
      FROM "products"
      WHERE "product_category_name" IN (
          SELECT "product_category_name"
          FROM "product_category_name_translation"
          WHERE "product_category_name_english" = 'toys'
      )
  )
  AND DATE("orders"."order_purchase_timestamp") BETWEEN '2017-01-01' AND '2018-08-29'
  GROUP BY "order_date"
),
stats AS (
  SELECT
    COUNT(*) AS N,
    SUM(x) AS sum_x,
    SUM(y) AS sum_y,
    SUM(x*x) AS sum_xx,
    SUM(x*y) AS sum_xy
  FROM daily_sales
),
regression AS (
  SELECT
    (N * sum_xy - sum_x * sum_y) / (N * sum_xx - sum_x * sum_x) AS m,
    (sum_y - ((N * sum_xy - sum_x * sum_y) / (N * sum_xx - sum_x * sum_x)) * sum_x) / N AS b
  FROM stats
),
predictions AS (
  SELECT
    DATE('2018-12-03', '+' || n || ' day') AS date,
    julianday(DATE('2018-12-03', '+' || n || ' day')) - julianday('2017-01-01') AS x
  FROM (
    SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
  )
),
predicted_sales AS (
  SELECT
    date,
    m * x + b AS y_hat
  FROM predictions, regression
),
moving_averages AS (
  SELECT
    t1.date,
    AVG(t2.y_hat) AS moving_avg
  FROM predicted_sales t1
  JOIN predicted_sales t2
    ON t2.date BETWEEN DATE(t1.date, '-2 day') AND DATE(t1.date, '+2 day')
  GROUP BY t1.date
)
SELECT
  SUM(moving_avg) AS "sum_of_moving_avg"
FROM moving_averages
WHERE date BETWEEN '2018-12-05' AND '2018-12-08';