WITH
-- 1. Assign a sequential index (1-36) to the first 36 monthly rows of each product
ranked AS (
    SELECT  m.product_id,
            m.mth,
            m.qty,
            ROW_NUMBER() OVER (PARTITION BY m.product_id
                               ORDER BY m.mth)          AS idx
    FROM    monthly_sales AS m
    WHERE   m.product_id IN (4160, 7790)
      AND   m.mth >= '2016-01-01'
),
ranked36 AS (
    SELECT *
    FROM   ranked
    WHERE  idx <= 36            -- keep only the first 36 months
),

-- 2. Calculate regression coefficients (slope & intercept) for each product
stats AS (
    SELECT  product_id,
            COUNT(*)                       AS n,
            SUM(idx)                       AS sum_x,
            SUM(qty)                       AS sum_y,
            SUM(idx*idx)                   AS sum_x2,
            SUM(idx*qty)                   AS sum_xy
    FROM    ranked36
    GROUP BY product_id
),
reg AS (
    SELECT  s.product_id,
            -- slope  = ( n·Σxy − Σx·Σy ) / ( n·Σx² − (Σx)² )
            (s.n*1.0*s.sum_xy - s.sum_x*1.0*s.sum_y) /
            (s.n*1.0*s.sum_x2 - s.sum_x*1.0*s.sum_x)          AS slope,
            -- intercept = ( Σy − slope·Σx ) / n
            (s.sum_y*1.0 -
             ((s.n*1.0*s.sum_xy - s.sum_x*1.0*s.sum_y) /
              (s.n*1.0*s.sum_x2 - s.sum_x*1.0*s.sum_x)) *
             s.sum_x) / s.n                                   AS intercept
    FROM    stats s
),

-- 3. Trend estimate for every stored observation (idx 1-36)
trend AS (
    SELECT  r.product_id,
            r.idx,
            r.mth,
            r.qty,
            reg.intercept + reg.slope*r.idx   AS trend_pred
    FROM    ranked36 AS r
    JOIN    reg       ON reg.product_id = r.product_id
),

-- 4. Seasonality factors built from time steps 7-30
season AS (
    SELECT  t.product_id,
            strftime('%m', t.mth)                            AS mon,
            AVG(t.qty*1.0 / NULLIF(t.trend_pred,0))          AS season_factor
    FROM    trend t
    WHERE   t.idx BETWEEN 7 AND 30
    GROUP BY t.product_id, strftime('%m', t.mth)
),

-- 5. Forecast months belonging to calendar year 2018 (idx 25-36)
forecast_2018 AS (
    SELECT  t.product_id,
            t.mth,
            t.trend_pred * s.season_factor   AS forecast_qty
    FROM    trend  AS t
    JOIN    season AS s
           ON s.product_id = t.product_id
          AND s.mon        = strftime('%m', t.mth)
    WHERE   t.mth BETWEEN '2018-01-01' AND '2018-12-31'
)

-- 6. Return average forecasted annual sales for 2018
SELECT  product_id,
        AVG(forecast_qty) AS avg_forecast_annual_sales_2018
FROM    forecast_2018
GROUP BY product_id
ORDER BY product_id;