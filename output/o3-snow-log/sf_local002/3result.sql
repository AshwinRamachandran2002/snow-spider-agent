/* 5-day symmetric moving-average of predicted toy sales for
   05-Dec-2018 – 08-Dec-2018 (sum of the four averages)            */

WITH date_series AS (                           -- 1.1 calendar days for training
    SELECT DATEADD(day, seq4(), '2017-01-01')::date AS dt
    FROM TABLE(GENERATOR(ROWCOUNT => 1000))        -- > 607 needed
),  
date_series_filtered AS (                         -- 1.2 keep until 29-Aug-2018
    SELECT dt
    FROM   date_series
    WHERE  dt <= '2018-08-29'
),                                                -- 1.3 realised toy sales per day
toy_sales AS (
    SELECT
        TO_DATE(o."order_purchase_timestamp")            AS dt,
        COUNT(*)                                         AS sales_qty
    FROM E_COMMERCE.E_COMMERCE."ORDERS"       o
    JOIN E_COMMERCE.E_COMMERCE."ORDER_ITEMS"  oi ON oi."order_id"   = o."order_id"
    JOIN E_COMMERCE.E_COMMERCE."PRODUCTS"     p  ON oi."product_id" = p."product_id"
    LEFT JOIN E_COMMERCE.E_COMMERCE."PRODUCT_CATEGORY_NAME_TRANSLATION" t
           ON p."product_category_name" = t."product_category_name"
    WHERE o."order_purchase_timestamp" BETWEEN '2017-01-01' AND '2018-08-29 23:59:59'
      AND LOWER(COALESCE(t."product_category_name_english",
                         p."product_category_name")) LIKE '%toy%'   -- toy items
    GROUP BY dt
),                                                -- 1.4 calendar merged with sales
training AS (
    SELECT
        ds.dt,
        COALESCE(ts.sales_qty, 0)                          AS y,
        DATEDIFF('day', '2017-01-01', ds.dt)              AS x
    FROM   date_series_filtered ds
    LEFT  JOIN toy_sales ts ON ds.dt = ts.dt
),                                                -- 2) regression parameters
stats AS (
    SELECT
        COUNT(*)                          AS n,
        SUM(x)                            AS sum_x,
        SUM(y)                            AS sum_y,
        SUM(x*y)                          AS sum_xy,
        SUM(x*x)                          AS sum_x2
    FROM training
),  
reg_params AS (
    SELECT
        (n*sum_xy - sum_x*sum_y) / (n*sum_x2 - sum_x*sum_x)            AS slope,
        (sum_y - ((n*sum_xy - sum_x*sum_y) / (n*sum_x2 - sum_x*sum_x))*sum_x) / n
                                                                       AS intercept
    FROM stats
),                                                -- 3) dates to predict (03-Dec-18 – 10-Dec-18)
future_dates AS (
    SELECT DATEADD(day, seq4(), '2018-12-03')::date AS dt
    FROM TABLE(GENERATOR(ROWCOUNT => 8))
),  
predictions AS (
    SELECT
        fd.dt,
        rp.intercept
        + rp.slope * DATEDIFF('day', '2017-01-01', fd.dt)  AS predicted_sales
    FROM future_dates fd
    CROSS JOIN reg_params rp
),                                                -- 4) 5-day symmetric moving average
ma AS (
    SELECT
        dt,
        AVG(predicted_sales) OVER (ORDER BY dt
                                   ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS ma_5
    FROM predictions
)                                                 -- 5) sum of MA for 05-Dec-18 – 08-Dec-18
SELECT ROUND(SUM(ma_5), 4) AS "sum_5day_moving_avg"
FROM   ma
WHERE  dt BETWEEN '2018-12-05' AND '2018-12-08';