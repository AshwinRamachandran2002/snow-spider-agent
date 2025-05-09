WITH base AS (           -- 36 months of history (Jan‑2016 ‑ Dec‑2018)
    SELECT
        product_id,
        qty,
        ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY mth) - 1 AS t   -- t = 0…35
    FROM monthly_sales
    WHERE product_id IN (4160, 7790)
      AND mth BETWEEN '2016-01-01' AND '2018-12-01'
),
weighted AS (            -- seasonality adjustment : keep time–steps 7‑30
    SELECT
        product_id,
        t,
        qty,
        CASE WHEN t BETWEEN 6 AND 29 THEN 1.0 ELSE 0.0 END AS w
    FROM base
),
stats AS (               -- weighted sums needed for regression coefficients
    SELECT
        product_id,
        SUM(w)                 AS sw,
        SUM(w*t)               AS swx,
        SUM(w*qty)             AS swy,
        SUM(w*t*t)             AS swxx,
        SUM(w*t*qty)           AS swxy
    FROM weighted
    GROUP BY product_id
),
coeff AS (               -- slope (b) of the weighted regression line
    SELECT
        product_id,
        CASE
            WHEN sw*swxx = swx*swx THEN 0
            ELSE (sw*swxy - swx*swy)*1.0/(sw*swxx - swx*swx)
        END AS slope,
        sw, swx, swy
    FROM stats
),
model AS (               -- intercept (a) of the regression line
    SELECT
        product_id,
        slope,
        CASE WHEN sw = 0 THEN 0 ELSE (swy - slope*swx)*1.0/sw END AS intercept
    FROM coeff
),
months AS (              -- the 12 forecast months of calendar‑year 2018
    SELECT 24 AS t UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL
    SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL
    SELECT 30 UNION ALL SELECT 31 UNION ALL SELECT 32 UNION ALL
    SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35
),
forecast AS (            -- monthly forecasts and annual total per product
    SELECT
        m.product_id,
        SUM(m.intercept + m.slope * mn.t) AS annual_forecast_qty
    FROM model  AS m
    CROSS JOIN months AS mn
    GROUP BY m.product_id
)
SELECT ROUND(AVG(annual_forecast_qty), 4) AS avg_forecasted_annual_sales_2018
FROM forecast;