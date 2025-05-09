WITH toy_sales AS (      -- 1)  daily toy revenue in the modelling window
    SELECT DATE(o."order_purchase_timestamp")           AS sale_date,
           SUM(oi."price")                              AS daily_sales
    FROM   "orders"        AS o
    JOIN   "order_items"   AS oi ON oi."order_id" = o."order_id"
    JOIN   "products"      AS p  ON p."product_id"      = oi."product_id"
    JOIN   "product_category_name_translation" AS t
           ON t."product_category_name" = p."product_category_name"
    WHERE  t."product_category_name_english" = 'toys'
      AND  o."order_status" = 'delivered'
      AND  DATE(o."order_purchase_timestamp")
              BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP  BY sale_date
),
stats AS (              -- 2)  regression sufficient–statistics
    SELECT COUNT(*)                                                    AS n,
           SUM(JULIANDAY(sale_date) - JULIANDAY('2017-01-01'))         AS sum_x,
           SUM(daily_sales)                                            AS sum_y,
           SUM((JULIANDAY(sale_date) - JULIANDAY('2017-01-01'))*
               daily_sales)                                            AS sum_xy,
           SUM((JULIANDAY(sale_date) - JULIANDAY('2017-01-01'))*
               (JULIANDAY(sale_date) - JULIANDAY('2017-01-01')))       AS sum_xx
    FROM   toy_sales
),
model AS (             -- 3)  slope & intercept of the linear regression
    SELECT ((n*sum_xy) - (sum_x*sum_y)) / ((n*sum_xx) - (sum_x*sum_x))      AS slope,
           (sum_y - (((n*sum_xy) - (sum_x*sum_y)) /
                     ((n*sum_xx) - (sum_x*sum_x))) * sum_x) / n             AS intercept
    FROM stats
),
forecast_days AS (     -- 4)  dates from 1-Dec-2018 to 10-Dec-2018
    WITH RECURSIVE nums(i) AS (
        SELECT 0
        UNION ALL
        SELECT i+1 FROM nums WHERE i < 9
    )
    SELECT DATE('2018-12-01','+'||i||' days') AS forecast_date
    FROM   nums
),
predicted AS (         -- 5)  point-forecast for each day
    SELECT f.forecast_date,
           m.intercept +
           m.slope * (JULIANDAY(f.forecast_date) - JULIANDAY('2017-01-01')) AS predicted_sales
    FROM   forecast_days f
           CROSS JOIN model m
),
ma5 AS (               -- 6)  5-day symmetric moving average
    SELECT p1.forecast_date,
           (SELECT AVG(p2.predicted_sales)
              FROM predicted p2
             WHERE p2.forecast_date BETWEEN
                   DATE(p1.forecast_date,'-2 days')
                   AND
                   DATE(p1.forecast_date,'+2 days'))                    AS ma5
    FROM   predicted p1
)
SELECT SUM(ma5) AS sum_of_four_ma5       -- 7)  required sum for 5-Dec-2018 → 8-Dec-2018
FROM   ma5
WHERE  forecast_date BETWEEN '2018-12-05' AND '2018-12-08';