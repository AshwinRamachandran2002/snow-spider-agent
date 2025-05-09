WITH toy_products AS (
    SELECT p.product_id
    FROM products p
    JOIN product_category_name_translation t
      ON t.product_category_name = p.product_category_name
    WHERE t.product_category_name_english = 'toys'
), 

daily_sales AS (
    SELECT 
        DATE(o.order_purchase_timestamp) AS order_date,
        SUM(oi.price)                    AS sales
    FROM order_items oi
    JOIN orders o USING(order_id)
    JOIN toy_products tp ON tp.product_id = oi.product_id
    WHERE o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP BY order_date
),

training AS (
    SELECT 
        sales,
        (JULIANDAY(order_date) - JULIANDAY('2017-01-01')) AS day_number
    FROM daily_sales
),

stats AS (
    SELECT
        COUNT(*)                        AS n,
        SUM(day_number)                 AS sum_x,
        SUM(sales)                      AS sum_y,
        SUM(day_number * sales)         AS sum_xy,
        SUM(day_number * day_number)    AS sum_x2
    FROM training
),

coeff AS (
    SELECT
        (n * sum_xy - sum_x * sum_y) * 1.0 
        / (n * sum_x2 - sum_x * sum_x)           AS slope,
        (sum_y - ((n * sum_xy - sum_x * sum_y) * 1.0 
                 / (n * sum_x2 - sum_x * sum_x)) * sum_x) 
        / n                                      AS intercept
    FROM stats
),

future_dates AS (
    SELECT '2018-12-03' AS pred_date UNION ALL
    SELECT '2018-12-04' UNION ALL
    SELECT '2018-12-05' UNION ALL
    SELECT '2018-12-06' UNION ALL
    SELECT '2018-12-07' UNION ALL
    SELECT '2018-12-08' UNION ALL
    SELECT '2018-12-09' UNION ALL
    SELECT '2018-12-10'
),

predictions AS (
    SELECT 
        fd.pred_date,
        c.intercept + c.slope * (JULIANDAY(fd.pred_date) - JULIANDAY('2017-01-01')) 
        AS predicted_sales
    FROM future_dates fd
    CROSS JOIN coeff c
),

moving_avg AS (
    SELECT 
        p1.pred_date                       AS center_date,
        AVG(p2.predicted_sales)            AS moving_avg
    FROM predictions p1
    JOIN predictions p2
      ON ABS(JULIANDAY(p2.pred_date) - JULIANDAY(p1.pred_date)) <= 2
    WHERE p1.pred_date IN ('2018-12-05','2018-12-06','2018-12-07','2018-12-08')
    GROUP BY p1.pred_date
)

SELECT 
    SUM(moving_avg) AS sum_of_5day_moving_averages
FROM moving_avg;