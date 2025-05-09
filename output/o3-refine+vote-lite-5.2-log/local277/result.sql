WITH
-- 1.  Keep the first 36 months of sales (Jan‑2016 … Dec‑2018)
base AS (
    SELECT
        product_id,
        qty,
        -- month index: Jan‑2016 = 1, Feb‑2016 = 2, … , Dec‑2018 = 36
        ( (CAST(strftime('%Y', mth) AS INTEGER) - 2016) * 12
          + (CAST(strftime('%m', mth) AS INTEGER) - 1) ) + 1 AS x
    FROM   monthly_sales
    WHERE  product_id IN (4160, 7790)
      AND  mth >= '2016-01-01'
      AND  mth <  date('2016-01-01', '+36 months')
),
-- 2.  Apply seasonality weights (time steps 7‑30 get double weight)
weighted AS (
    SELECT
        product_id,
        x,
        qty,
        CASE WHEN x BETWEEN 7 AND 30 THEN 2 ELSE 1 END AS w
    FROM   base
),
-- 3.  Compute the weighted‑least‑squares regression coefficients
stats AS (
    SELECT
        product_id,
        SUM(w)              AS S0,
        SUM(w * x)          AS Sx,
        SUM(w * qty)        AS Sy,
        SUM(w * x * x)      AS Sxx,
        SUM(w * x * qty)    AS Sxy
    FROM   weighted
    GROUP  BY product_id
),
coeff AS (
    SELECT
        product_id,
        (S0 * Sxy - Sx * Sy) * 1.0 / (S0 * Sxx - Sx * Sx)            AS slope,
        (Sy - ((S0 * Sxy - Sx * Sy) * 1.0 / (S0 * Sxx - Sx * Sx)) * Sx) * 1.0 / S0 AS intercept
    FROM   stats
),
-- 4.  Generate the 2018 month indices (25‑36) and forecast each month
forecast_months AS (
    SELECT 25 AS x UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28
    UNION ALL SELECT 29 UNION ALL SELECT 30 UNION ALL SELECT 31 UNION ALL SELECT 32
    UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35 UNION ALL SELECT 36
),
forecast AS (
    SELECT
        c.product_id,
        fm.x,
        c.intercept + c.slope * fm.x AS predicted_qty
    FROM   coeff c
    CROSS  JOIN forecast_months fm
),
-- 5.  Yearly total per product
annual AS (
    SELECT
        product_id,
        SUM(predicted_qty) AS annual_qty
    FROM   forecast
    GROUP  BY product_id
)
-- 6.  Average of the two products’ 2018 forecasts
SELECT
    ROUND(AVG(annual_qty), 4) AS avg_forecasted_annual_sales_2018
FROM   annual;