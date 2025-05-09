WITH training AS (      -- the first 36 months starting 2016‑01‑01
    SELECT  product_id ,
            mth ,
            qty ,
            ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY mth)  AS t ,
            CAST( strftime('%m',mth) AS INTEGER )                    AS month_no
    FROM    monthly_sales
    WHERE   product_id IN (4160,7790)
      AND   mth >= '2016-01-01'
      AND   mth <  '2019-01-01'               -- 36 months = 2016‑01‑01 … 2018‑12‑01
),
stats AS (               -- weighted‑regression building blocks (weight=w=t)
    SELECT  product_id,
            SUM(t)                 AS sum_w,
            SUM(t*t)               AS sum_wx,
            SUM(t*qty)             AS sum_wy,
            SUM(t*t*t)             AS sum_wx2,
            SUM(t*t*qty)           AS sum_wxy
    FROM    training
    GROUP BY product_id
),
coef AS (                -- slope & intercept from weighted least squares
    SELECT  product_id,
            (sum_w*sum_wxy - sum_wx*sum_wy) * 1.0 /
            NULLIF(sum_w*sum_wx2 - sum_wx*sum_wx,0)          AS slope,
            (sum_wy -
             ((sum_w*sum_wxy - sum_wx*sum_wy) * 1.0 /
              NULLIF(sum_w*sum_wx2 - sum_wx*sum_wx,0))*sum_wx) * 1.0 /
            sum_w                                            AS intercept
    FROM    stats
),
trend AS (               -- trend value for every month
    SELECT  tr.product_id,
            tr.mth,
            tr.qty,
            tr.t,
            tr.month_no,
            c.intercept + c.slope*tr.t                       AS trend_val
    FROM    training tr
    JOIN    coef c USING (product_id)
),
season AS (              -- seasonal indices from time‑steps 7 … 30
    SELECT  product_id,
            month_no,
            AVG( qty / NULLIF(trend_val,0) )                 AS seasonal_index
    FROM    trend
    WHERE   t BETWEEN 7 AND 30
    GROUP BY product_id, month_no
),
forecast AS (            -- 2018 forecast = trend × seasonal index
    SELECT  tr.product_id,
            tr.t,
            (c.intercept + c.slope*tr.t) * s.seasonal_index  AS forecast_qty
    FROM    trend tr
    JOIN    coef   c USING (product_id)
    JOIN    season s ON s.product_id = tr.product_id
                    AND s.month_no   = tr.month_no
    WHERE   tr.mth BETWEEN '2018-01-01' AND '2018-12-31'
)
SELECT  ROUND( AVG(annual_forecast), 4 ) AS avg_forecast_annual_sales_2018
FROM   (
        SELECT  product_id,
                SUM(forecast_qty) AS annual_forecast
        FROM    forecast
        GROUP BY product_id
       );