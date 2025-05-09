WITH RECURSIVE dates(d) AS (                       -- every day in the training span
    SELECT DATE('2017-01-01')
    UNION ALL
    SELECT DATE(d,'+1 day') FROM dates WHERE d<'2018-08-29'
),
toy_daily AS (                                     -- delivered toy sales per day
    SELECT DATE(o."order_purchase_timestamp") AS d,
           COUNT(oi."order_item_id")          AS y
    FROM   "orders"  o
    JOIN   "order_items" oi ON o."order_id" = oi."order_id"
    JOIN   "products"      p ON oi."product_id" = p."product_id"
    JOIN   "product_category_name_translation" t
           ON p."product_category_name" = t."product_category_name"
    WHERE  t."product_category_name_english" = 'toys'
      AND  o."order_status" = 'delivered'
      AND  DATE(o."order_purchase_timestamp")
           BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP  BY DATE(o."order_purchase_timestamp")
),
training AS (                                     -- include zero‑sale days
    SELECT d,
           CAST(julianday(d) - julianday('2017-01-01') AS REAL) AS x,
           COALESCE(y,0) AS y
    FROM   dates
    LEFT JOIN toy_daily USING (d)
),
stats AS (                                        -- regression aggregates
    SELECT COUNT(*) AS n,
           SUM(x)   AS sx,
           SUM(y)   AS sy,
           SUM(x*y) AS sxy,
           SUM(x*x) AS sxx
    FROM   training
),
coeff AS (                                        -- slope (b) and intercept (a)
    SELECT (n*sxy - sx*sy)/(n*sxx - sx*sx)                AS b,
           (sy - ((n*sxy - sx*sy)/(n*sxx - sx*sx))*sx)/n  AS a
    FROM   stats
),
pred_dates(d) AS (                                -- dates needed for MA windows
    VALUES ('2018-12-03'),('2018-12-04'),('2018-12-05'),('2018-12-06'),
           ('2018-12-07'),('2018-12-08'),('2018-12-09'),('2018-12-10')
),
pred_values AS (                                  -- regression predictions
    SELECT d,
           (SELECT a FROM coeff) +
           (SELECT b FROM coeff)*(julianday(d) - julianday('2017-01-01')) AS y_pred
    FROM   pred_dates
),
five_ma AS (                                      -- 5‑day symmetric moving averages
    SELECT d AS sale_date,
           (SELECT AVG(y_pred)
              FROM pred_values p2
              WHERE p2.d BETWEEN DATE(p1.d,'-2 day') AND DATE(p1.d,'+2 day')
           ) AS ma5
    FROM   pred_values p1
    WHERE  d BETWEEN '2018-12-05' AND '2018-12-08'
)
SELECT sale_date,
       ROUND(ma5,4) AS "5_day_symmetric_moving_average"
FROM   five_ma
UNION ALL
SELECT 'sum',
       ROUND(SUM(ma5),4)
FROM   five_ma
ORDER BY sale_date;