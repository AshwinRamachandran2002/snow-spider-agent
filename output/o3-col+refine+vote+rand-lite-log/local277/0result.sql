WITH base AS (      -- 36 months of history: Jan-2016 … Dec-2018
    SELECT  product_id,
            mth,
            qty,
            ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY mth)             AS rn,
            CAST(strftime('%m',mth) AS INTEGER)                                  AS mon
    FROM    monthly_sales
    WHERE   product_id IN (4160,7790)
      AND   mth BETWEEN '2016-01-01' AND '2018-12-01'
),
-- weighted-regression building blocks   (weight = rn)
stats AS (
    SELECT  product_id,
            SUM(rn)                        AS sum_w,          -- Σw
            SUM(rn*rn)                     AS sum_wx,         -- Σw·x
            SUM(rn*qty)                    AS sum_wy,         -- Σw·y
            SUM(rn*rn*qty)                 AS sum_wxy,        -- Σw·x·y
            SUM(rn*rn*rn)                  AS sum_wxx         -- Σw·x²
    FROM    base
    GROUP BY product_id
),
coeff AS (          -- slope & intercept of the weighted regression line
    SELECT  product_id,
            (sum_w * sum_wxy - sum_wx * sum_wy) /
            (sum_w * sum_wxx - sum_wx * sum_wx)                                AS slope,
            (sum_wy - ((sum_w * sum_wxy - sum_wx * sum_wy) /
                       (sum_w * sum_wxx - sum_wx * sum_wx)) * sum_wx) / sum_w  AS intercept
    FROM    stats
),
pred AS (           -- base (un-seasonal) prediction for every observed month
    SELECT  b.product_id,
            b.mth,
            b.mon,
            b.rn,
            b.qty,
            c.intercept + c.slope * b.rn          AS base_pred
    FROM    base b
    JOIN    coeff c USING (product_id)
),
season AS (         -- seasonality factors from time-steps 7-30
    SELECT  product_id,
            mon,
            AVG(CASE WHEN base_pred=0 THEN 1.0
                     ELSE qty*1.0/base_pred END) AS season_factor
    FROM    pred
    WHERE   rn BETWEEN 7 AND 30
    GROUP BY product_id,mon
),
forecast AS (       -- seasonally adjusted forecast for the year 2018 (rn 25-36)
    SELECT  p.product_id,
            p.mth,
            p.base_pred * s.season_factor AS forecast_qty
    FROM    pred  p
    JOIN    season s
         ON s.product_id = p.product_id
        AND s.mon        = p.mon
    WHERE   p.rn BETWEEN 25 AND 36        -- Jan-2018 … Dec-2018
),
annual AS (
    SELECT  product_id,
            SUM(forecast_qty)             AS forecast_annual_qty
    FROM    forecast
    GROUP BY product_id
)
SELECT  ROUND(AVG(forecast_annual_qty),4) AS avg_forecast_annual_qty_2018
FROM    annual;