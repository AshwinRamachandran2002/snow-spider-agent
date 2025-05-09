WITH RECURSIVE
    -- calendar of days from 2017‑01‑01 to 2018‑12‑10
    calendar(date) AS (
        SELECT DATE('2017-01-01')
        UNION ALL
        SELECT DATE(date,'+1 day')
        FROM   calendar
        WHERE  date < '2018-12-10'
    ),
    
    -- daily toy sales in the training window
    sales AS (
        SELECT DATE(o.order_purchase_timestamp) AS date,
               SUM(oi.price)                  AS sales
        FROM   order_items                     oi
        JOIN   products                        p  ON p.product_id = oi.product_id
        JOIN   product_category_name_translation t
               ON t.product_category_name = p.product_category_name
        JOIN   orders                          o  ON o.order_id = oi.order_id
        WHERE  t.product_category_name_english = 'toys'
          AND  DATE(o.order_purchase_timestamp) BETWEEN '2017-01-01' AND '2018-08-29'
        GROUP  BY DATE(o.order_purchase_timestamp)
    ),
    
    -- training set with continuous dates (fill gaps with 0)
    training AS (
        SELECT c.date,
               COALESCE(s.sales,0.0)                                       AS y,
               CAST(julianday(c.date) - julianday('2017-01-01') AS REAL)   AS x
        FROM   calendar c
        LEFT   JOIN sales s USING(date)
        WHERE  c.date <= '2018-08-29'
    ),
    
    -- regression statistics
    stats AS (
        SELECT COUNT(*)          AS n,
               SUM(x)            AS sum_x,
               SUM(y)            AS sum_y,
               SUM(x*x)          AS sum_x2,
               SUM(x*y)          AS sum_xy
        FROM   training
    ),
    
    -- slope (b) and intercept (a)
    coeffs AS (
        SELECT ( (n*sum_xy - sum_x*sum_y) / (n*sum_x2 - sum_x*sum_x) )      AS b,
               ( (sum_y - ((n*sum_xy - sum_x*sum_y) / (n*sum_x2 - sum_x*sum_x))*sum_x) / n ) AS a
        FROM   stats
    ),
    
    -- predicted toy sales for every calendar date
    predictions AS (
        SELECT c.date,
               a + b*(julianday(c.date) - julianday('2017-01-01')) AS predicted
        FROM   calendar c, coeffs
    ),
    
    -- 5‑day symmetric moving averages for 5‑8 Dec 2018
    moving_avgs AS (
        SELECT p.date,
               (SELECT AVG(p2.predicted)
                FROM   predictions p2
                WHERE  p2.date BETWEEN DATE(p.date,'-2 day') AND DATE(p.date,'+2 day')
               ) AS ma5
        FROM   predictions p
        WHERE  p.date BETWEEN '2018-12-05' AND '2018-12-08'
    )

SELECT SUM(ma5) AS sum_of_four_5day_moving_averages
FROM   moving_avgs;