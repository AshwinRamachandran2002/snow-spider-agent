WITH daily_sales AS (
  SELECT
    DATE(o."order_purchase_timestamp") AS "order_date",
    (julianday(DATE(o."order_purchase_timestamp")) - julianday('2017-01-01')) AS xi,
    SUM(oi."price") AS yi
  FROM "order_items" oi
  JOIN "products" p ON oi."product_id" = p."product_id"
  JOIN "product_category_name_translation" t ON p."product_category_name" = t."product_category_name"
  JOIN "orders" o ON oi."order_id" = o."order_id"
  WHERE t."product_category_name_english" = 'toys'
    AND DATE(o."order_purchase_timestamp") BETWEEN '2017-01-01' AND '2018-08-29'
  GROUP BY "order_date"
  ORDER BY "order_date"
),
regression_coefficients AS (
  SELECT
    COUNT(*) AS N,
    SUM(xi) AS sum_xi,
    SUM(yi) AS sum_yi,
    SUM(xi * yi) AS sum_xi_yi,
    SUM(xi * xi) AS sum_xi2
  FROM daily_sales
),
coefficients AS (
  SELECT
    ( (N * sum_xi_yi - sum_xi * sum_yi) / (N * sum_xi2 - sum_xi * sum_xi) ) AS b,
    ( (sum_yi * sum_xi2 - sum_xi * sum_xi_yi) / (N * sum_xi2 - sum_xi * sum_xi) ) AS a
  FROM regression_coefficients
),
dates(date) AS (
  SELECT DATE('2018-08-30')
  UNION ALL
  SELECT DATE(date, '+1 day')
  FROM dates
  WHERE date < '2018-12-10'
),
predicted_sales AS (
  SELECT
    date AS order_date,
    (julianday(date) - julianday('2017-01-01')) AS xi,
    a + b * (julianday(date) - julianday('2017-01-01')) AS predicted_sales
  FROM dates
  CROSS JOIN coefficients
),
moving_averages AS (
  SELECT
    ps1.order_date,
    AVG(ps2.predicted_sales) AS moving_average
  FROM predicted_sales ps1
  JOIN predicted_sales ps2
    ON ps2.order_date BETWEEN date(ps1.order_date, '-2 day') AND date(ps1.order_date, '+2 day')
  WHERE ps1.order_date BETWEEN '2018-12-05' AND '2018-12-08'
  GROUP BY ps1.order_date
)
SELECT ROUND(SUM(moving_average), 4) AS "Total_Moving_Average"
FROM moving_averages;