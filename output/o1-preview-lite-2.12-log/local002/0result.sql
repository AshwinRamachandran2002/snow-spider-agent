WITH daily_sales AS (
    SELECT 
        DATE(o."order_purchase_timestamp") AS sale_date, 
        SUM(oi."price") AS daily_sales,
        (JULIANDAY(DATE(o."order_purchase_timestamp")) - JULIANDAY('2017-01-01')) AS day_number
    FROM "order_items" oi
    JOIN "orders" o ON oi."order_id" = o."order_id"
    JOIN "products" p ON oi."product_id" = p."product_id"
    JOIN "product_category_name_translation" t ON p."product_category_name" = t."product_category_name"
    WHERE t."product_category_name_english" = 'toys'
      AND o."order_purchase_timestamp" BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP BY sale_date
),
summaries AS (
    SELECT 
        COUNT(*) AS n,
        SUM(day_number) AS sum_x,
        SUM(daily_sales) AS sum_y,
        SUM(day_number * day_number) AS sum_xx,
        SUM(day_number * daily_sales) AS sum_xy
    FROM daily_sales
),
regression AS (
    SELECT
        (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x) AS m,
        (sum_y - ((n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x)) * sum_x) / n AS b
    FROM summaries
),
dates_to_predict AS (
    SELECT '2018-12-03' AS sale_date, JULIANDAY('2018-12-03') - JULIANDAY('2017-01-01') AS day_number UNION ALL
    SELECT '2018-12-04', JULIANDAY('2018-12-04') - JULIANDAY('2017-01-01') UNION ALL
    SELECT '2018-12-05', JULIANDAY('2018-12-05') - JULIANDAY('2017-01-01') UNION ALL
    SELECT '2018-12-06', JULIANDAY('2018-12-06') - JULIANDAY('2017-01-01') UNION ALL
    SELECT '2018-12-07', JULIANDAY('2018-12-07') - JULIANDAY('2017-01-01') UNION ALL
    SELECT '2018-12-08', JULIANDAY('2018-12-08') - JULIANDAY('2017-01-01') UNION ALL
    SELECT '2018-12-09', JULIANDAY('2018-12-09') - JULIANDAY('2017-01-01') UNION ALL
    SELECT '2018-12-10', JULIANDAY('2018-12-10') - JULIANDAY('2017-01-01')
),
predictions AS (
    SELECT 
        d.sale_date,
        d.day_number,
        regression.m * d.day_number + regression.b AS predicted_sales
    FROM dates_to_predict d
    CROSS JOIN regression
),
target_dates AS (
    SELECT '2018-12-05' AS sale_date UNION ALL
    SELECT '2018-12-06' UNION ALL
    SELECT '2018-12-07' UNION ALL
    SELECT '2018-12-08'
),
moving_averages AS (
    SELECT td.sale_date AS target_date, AVG(p2.predicted_sales) AS moving_average
    FROM target_dates td
    JOIN predictions p1 ON td.sale_date = p1.sale_date
    JOIN predictions p2 ON ABS(p2.day_number - p1.day_number) <= 2
    GROUP BY td.sale_date
),
sum_moving_averages AS (
    SELECT SUM(moving_average) AS sum_of_moving_averages
    FROM moving_averages
)
SELECT ROUND(sum_of_moving_averages, 4) AS "Sum_of_5-day_Symmetric_Moving_Averages"
FROM sum_moving_averages;