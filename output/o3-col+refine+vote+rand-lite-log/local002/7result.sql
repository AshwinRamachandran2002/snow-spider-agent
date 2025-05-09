WITH toy_categories AS (          -- Portuguese toy-category names
         SELECT 'brinquedos'                  AS product_category_name
  UNION ALL SELECT 'bebes_brincadeiras'
  UNION ALL SELECT 'brinquedos_partes_e_pecas'
),
toy_products AS (                 -- every toy product id
  SELECT product_id
  FROM   products
  WHERE  product_category_name IN (SELECT product_category_name
                                   FROM   toy_categories)
),
toy_sales AS (                    -- daily toy sales 2017-01-01 → 2018-08-29
  SELECT DATE(o.order_purchase_timestamp)                                     AS d,
         COUNT(*)                                                             AS y,
         (JULIANDAY(DATE(o.order_purchase_timestamp)) -
          JULIANDAY('2017-01-01'))                                           AS x
  FROM   order_items  oi
  JOIN   orders       o  ON o.order_id = oi.order_id
  WHERE  oi.product_id IN (SELECT product_id FROM toy_products)
    AND  DATE(o.order_purchase_timestamp) BETWEEN '2017-01-01' AND '2018-08-29'
  GROUP  BY d
),
stats AS (                         -- aggregates for simple-linear-regression
  SELECT COUNT(*)            AS n,
         SUM(x)              AS sx,
         SUM(y)              AS sy,
         SUM(x*y)            AS sxy,
         SUM(x*x)            AS sx2
  FROM   toy_sales
),
coeff AS (                         -- slope & intercept  (y = a + b·x)
  SELECT (n*sxy - sx*sy)*1.0 / (n*sx2 - sx*sx)               AS slope,
         (sy - ((n*sxy - sx*sy)*1.0 / (n*sx2 - sx*sx))*sx)*1.0/n
                                                           AS intercept
  FROM   stats
),
future_dates AS (                  -- 03-Dec-2018 → 10-Dec-2018
  SELECT '2018-12-03' AS d UNION ALL SELECT '2018-12-04'
  UNION ALL SELECT '2018-12-05' UNION ALL SELECT '2018-12-06'
  UNION ALL SELECT '2018-12-07' UNION ALL SELECT '2018-12-08'
  UNION ALL SELECT '2018-12-09' UNION ALL SELECT '2018-12-10'
),
predicted AS (                     -- regression prediction for each day
  SELECT d,
         coeff.intercept +
         coeff.slope*(JULIANDAY(d) - JULIANDAY('2017-01-01'))   AS yhat
  FROM   future_dates
  CROSS  JOIN coeff
),
ma5 AS (                            -- 5-day symmetric moving average
  SELECT a.d,
         (SELECT AVG(b.yhat)
          FROM   predicted b
          WHERE  JULIANDAY(b.d)
                 BETWEEN JULIANDAY(a.d)-2 AND JULIANDAY(a.d)+2) AS ma5_value
  FROM   predicted a
)
SELECT ROUND(SUM(ma5_value),4) AS sum_of_four_MA5
FROM   ma5
WHERE  d BETWEEN '2018-12-05' AND '2018-12-08';