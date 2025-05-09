WITH daily_sales AS (
    /* 1. Daily toy-sales between 2017-01-01 and 2018-08-29 */
    SELECT DATE(o."order_purchase_timestamp") AS sales_date,
           COUNT(*)                          AS toy_sales
    FROM   "order_items"  AS oi
    JOIN   "orders"       AS o ON o."order_id"  = oi."order_id"
    JOIN   "products"     AS p ON p."product_id" = oi."product_id"
    WHERE  p."product_category_name" = 'brinquedos'
      AND  DATE(o."order_purchase_timestamp") 
           BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP  BY DATE(o."order_purchase_timestamp")
),
indexed AS (
    /* 2. Give each day an index for regression math                       */
    SELECT ROW_NUMBER() OVER (ORDER BY sales_date) AS idx,
           toy_sales
    FROM   daily_sales
),
params AS (
    /* 3. Simple-linear-regression parameters (slope & intercept)          */
    SELECT (COUNT(*) * SUM(idx * toy_sales) - SUM(idx) * SUM(toy_sales)) * 1.0 /
           (COUNT(*) * SUM(idx * idx)       - SUM(idx) * SUM(idx))  AS slope,
           (SUM(toy_sales) * 1.0 / COUNT(*)) -
           ((COUNT(*) * SUM(idx * toy_sales) - SUM(idx) * SUM(toy_sales)) * 1.0 /
            (COUNT(*) * SUM(idx * idx)       - SUM(idx) * SUM(idx))) *
           (SUM(idx) * 1.0 / COUNT(*))                              AS intercept
    FROM   indexed
),
dates AS (
    /* 4. Prediction window                                                */
    SELECT '2018-12-03' AS d UNION ALL SELECT '2018-12-04' UNION ALL
    SELECT '2018-12-05' UNION ALL SELECT '2018-12-06' UNION ALL
    SELECT '2018-12-07' UNION ALL SELECT '2018-12-08' UNION ALL
    SELECT '2018-12-09' UNION ALL SELECT '2018-12-10'
),
predictions AS (
    /* 5. Predicted toy-sales for each date                                */
    SELECT d,
           (SELECT intercept FROM params) +
           (SELECT slope     FROM params) *
           (julianday(d) - julianday('2017-01-01') + 1)  AS predicted_sales
    FROM   dates
),
moving_avg AS (
    /* 6. 5-day symmetric moving average (centered window of width 5)      */
    SELECT p1.d,
           (SELECT AVG(p2.predicted_sales)
            FROM   predictions p2
            WHERE  julianday(p2.d) BETWEEN julianday(p1.d) - 2
                                      AND     julianday(p1.d) + 2)  AS ma5
    FROM   predictions p1
)
/* 7. Sum of the four MA₅ values from 5-Dec-2018 to 8-Dec-2018              */
SELECT ROUND(SUM(ma5), 4) AS sum_of_ma5
FROM   moving_avg
WHERE  d BETWEEN '2018-12-05' AND '2018-12-08';