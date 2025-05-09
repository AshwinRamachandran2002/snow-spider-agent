WITH RECURSIVE calendar(dt, idx) AS (            -- continuous date series to 2018-12-10
        SELECT DATE('2017-01-01'), 0
        UNION ALL
        SELECT DATE(dt,'+1 day'), idx+1
        FROM   calendar
        WHERE  dt < DATE('2018-12-10')
),
daily_sales AS (                                   -- actual toy sales (training set)
        SELECT DATE(o."order_purchase_timestamp")              AS sale_date,
               SUM(oi."price")                                 AS daily_revenue
        FROM   "order_items"  AS oi
        JOIN   "orders"       AS o ON o."order_id" = oi."order_id"
        JOIN   "products"     AS p ON p."product_id" = oi."product_id"
        JOIN   "product_category_name_translation" AS t
               ON p."product_category_name" = t."product_category_name"
        WHERE  t."product_category_name_english" = 'toys'
          AND  DATE(o."order_purchase_timestamp")
               BETWEEN '2017-01-01' AND '2018-08-29'
        GROUP  BY sale_date
),
training_series AS (                              -- fill missing days with zero sales
        SELECT c.idx,
               COALESCE(ds.daily_revenue,0.0) AS y
        FROM   calendar AS c
        LEFT   JOIN daily_sales AS ds
               ON ds.sale_date = c.dt
        WHERE  c.dt BETWEEN '2017-01-01' AND '2018-08-29'
),
stats AS (                                        -- regression statistics
        SELECT COUNT(*)                          AS n,
               SUM(idx)                          AS sx,
               SUM(y)                            AS sy,
               SUM(idx*y)                        AS sxy,
               SUM(idx*idx)                      AS sx2
        FROM   training_series
),
params AS (                                       -- slope & intercept
        SELECT (n*sxy - sx*sy) / (n*sx2 - sx*sx)                        AS slope,
               (sy - ((n*sxy - sx*sy) / (n*sx2 - sx*sx))*sx) / n        AS intercept
        FROM   stats
),
predictions AS (                                  -- forecast every day to 2018-12-10
        SELECT c.dt,
               p.intercept + p.slope*c.idx AS predicted_sales
        FROM   calendar AS c
        CROSS  JOIN params AS p
),
ma5 AS (                                           -- 5-day symmetric moving average
        SELECT dt AS prediction_date,
               AVG(predicted_sales)
               OVER (ORDER BY dt ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
               AS five_day_symmetric_ma
        FROM   predictions
)
SELECT ROUND(SUM(five_day_symmetric_ma),4) AS sum_of_5day_symmetric_moving_averages
FROM   ma5
WHERE  prediction_date BETWEEN '2018-12-05' AND '2018-12-08';