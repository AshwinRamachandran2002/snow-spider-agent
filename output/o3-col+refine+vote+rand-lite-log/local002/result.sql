WITH daily AS (                          -- 1.  actual daily toy-sales 2017-01-01 … 2018-08-29
    SELECT DATE(o.order_purchase_timestamp)                                                AS dt,
           COUNT(*)                                                                        AS y,
           julianday(DATE(o.order_purchase_timestamp)) - julianday('2017-01-01')          AS x
    FROM   order_items  AS oi
    JOIN   orders       AS o  ON o.order_id = oi.order_id
    JOIN   products     AS p  ON p.product_id = oi.product_id
    WHERE  p.product_category_name = 'brinquedos'
      AND  DATE(o.order_purchase_timestamp) BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP  BY dt
),
stats AS (                          -- 2. regression sums
    SELECT COUNT(*) AS n,
           SUM(x)   AS sx,
           SUM(y)   AS sy,
           SUM(x*x) AS sx2,
           SUM(x*y) AS sxy
    FROM daily
),
coeff AS (                          -- 3. slope (m) and intercept (b)
    SELECT (n*sxy - sx*sy) / (n*sx2 - sx*sx)                          AS m,
           (sy - ((n*sxy - sx*sy)/(n*sx2 - sx*sx))*sx) / n           AS b
    FROM stats
),
num(n) AS (                        -- 4. generator:  eight consecutive days 03-Dec … 10-Dec-2018
    SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
),
future AS (
    SELECT DATE('2018-12-03', '+'||n||' day') AS d
    FROM   num
),
pred AS (                          -- 5. predicted sales for each future day
    SELECT f.d,
           (c.m * (julianday(f.d) - julianday('2017-01-01')) + c.b)  AS yhat
    FROM   future AS f, coeff AS c
),
ma5 AS (                           -- 6. 5-day centred moving average of the predictions
    SELECT p1.d,
           (SELECT AVG(p2.yhat)
              FROM pred AS p2
             WHERE p2.d BETWEEN DATE(p1.d,'-2 day') AND DATE(p1.d,'+2 day')
           )                                                          AS ma_5day
    FROM pred AS p1
)
SELECT ROUND(SUM(ma_5day),4) AS sum_5day_moving_avg_dec5_to_dec8     -- 7. final answer
FROM   ma5
WHERE  d BETWEEN '2018-12-05' AND '2018-12-08';