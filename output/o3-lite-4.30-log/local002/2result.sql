WITH toys_pt AS (
  SELECT product_category_name
  FROM product_category_name_translation
  WHERE product_category_name_english = 'toys'
),
daily_sales AS (
  SELECT
        DATE(o.order_purchase_timestamp)                                                 AS sales_date,
        COUNT(*)                                                                         AS qty,
        julianday(DATE(o.order_purchase_timestamp)) - julianday('2017-01-01')            AS x
  FROM   orders        AS o
  JOIN   order_items   AS oi  ON oi.order_id    = o.order_id
  JOIN   products      AS p   ON p.product_id   = oi.product_id
  JOIN   toys_pt       AS t   ON t.product_category_name = p.product_category_name
  WHERE  DATE(o.order_purchase_timestamp) BETWEEN '2017-01-01' AND '2018-08-29'
  GROUP  BY sales_date
),
params AS (
  SELECT
        (COUNT(*)*SUM(x*qty) - SUM(x)*SUM(qty)) /
        (COUNT(*)*SUM(x*x)   - SUM(x)*SUM(x))                                           AS b,
        (SUM(qty) -
         ((COUNT(*)*SUM(x*qty) - SUM(x)*SUM(qty)) /
          (COUNT(*)*SUM(x*x)  - SUM(x)*SUM(x)))*SUM(x)) /
         COUNT(*)                                                                       AS a
  FROM   daily_sales
),
date_series AS (
  SELECT DATE('2018-12-01', '+'||n||' day') AS forecast_date
  FROM  (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL
         SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
         SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
         SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11)
),
pred AS (
  SELECT
        ds.forecast_date,
        p.a + p.b * (julianday(ds.forecast_date) - julianday('2017-01-01'))             AS qty
  FROM  date_series ds
  CROSS JOIN params p
),
mov5 AS (
  SELECT
        target.forecast_date                                                             AS center_date,
        AVG(neigh.qty)                                                                   AS moving_avg_5d
  FROM  pred  AS target
  JOIN  pred  AS neigh
        ON neigh.forecast_date BETWEEN DATE(target.forecast_date,'-2 day')
                                   AND     DATE(target.forecast_date,'+2 day')
  GROUP BY target.forecast_date
),
selected AS (
  SELECT center_date AS sale_date, moving_avg_5d
  FROM   mov5
  WHERE  center_date BETWEEN '2018-12-05' AND '2018-12-08'
)
SELECT
      sale_date,
      printf('%.4f', moving_avg_5d) AS "5_day_symmetric_moving_average"
FROM (
      SELECT sale_date, moving_avg_5d FROM selected
      UNION ALL
      SELECT 'sum_4_avgs', SUM(moving_avg_5d) FROM selected
)
ORDER BY CASE WHEN sale_date LIKE '2018-%' THEN 0 ELSE 1 END,
         sale_date;