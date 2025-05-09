WITH RECURSIVE
-- 1. toy order‑items between 2017‑01‑01 and 2018‑08‑29
toy_lines AS (
    SELECT DATE(o.order_purchase_timestamp) AS order_date
    FROM   order_items AS oi
    JOIN   orders      AS o ON o.order_id = oi.order_id
    JOIN   products    AS p ON p.product_id = oi.product_id
    JOIN   product_category_name_translation AS t
           ON t.product_category_name = p.product_category_name
    WHERE  t.product_category_name_english = 'toys'
      AND  DATE(o.order_purchase_timestamp) BETWEEN '2017-01-01' AND '2018-08-29'
),
-- 2. daily toy‑unit sales
daily AS (
    SELECT order_date,
           COUNT(*) AS y
    FROM   toy_lines
    GROUP  BY order_date
),
-- 3. regression summary terms
stats AS (
    SELECT
        COUNT(*)                                       AS n,
        SUM(x)                                         AS sum_x,
        SUM(y)                                         AS sum_y,
        SUM(x*x)                                       AS sum_x2,
        SUM(x*y)                                       AS sum_xy
    FROM (
        SELECT
            CAST(julianday(order_date) - julianday('2017-01-01') AS INTEGER) AS x,
            y
        FROM   daily
    )
),
-- 4. regression coefficients  (ŷ = slope·x + intercept)
coeff AS (
    SELECT
        (n*sum_xy - sum_x*sum_y)*1.0 /
        (n*sum_x2 - sum_x*sum_x)                                AS slope,
        (sum_y - ((n*sum_xy - sum_x*sum_y)*1.0 /
                 (n*sum_x2 - sum_x*sum_x))*sum_x)*1.0/n         AS intercept
    FROM stats
),
-- 5. sequence 0 … 7 to build the eight forecast dates
seq(i) AS (
    SELECT 0
    UNION ALL
    SELECT i+1 FROM seq WHERE i < 7
),
forecast_dates AS (
    SELECT DATE('2018-12-03','+'||i||' day') AS d
    FROM   seq
),
-- 6. predicted toy sales for each forecast date
pred AS (
    SELECT
        d AS forecast_date,
        slope * CAST(julianday(d) - julianday('2017-01-01') AS INTEGER)
        + intercept                                          AS y_hat
    FROM   forecast_dates
    CROSS  JOIN coeff
),
-- 7. centred 5‑day moving average
ma5 AS (
    SELECT
        p1.forecast_date               AS center_day,
        AVG(p2.y_hat)                  AS ma5
    FROM   pred AS p1
    JOIN   pred AS p2
           ON julianday(p2.forecast_date)
              BETWEEN julianday(p1.forecast_date,'-2 days')
                  AND julianday(p1.forecast_date,'+2 days')
    GROUP  BY p1.forecast_date
)
-- 8. sum of the four 5‑day moving averages (05‑Dec‑2018 … 08‑Dec‑2018)
SELECT
    SUM(ma5) AS sum_of_4_moving_averages
FROM   ma5
WHERE  center_day BETWEEN '2018-12-05' AND '2018-12-08';