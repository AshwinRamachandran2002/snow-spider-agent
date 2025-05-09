WITH base AS (
    SELECT
        product_id,
        ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY mth) AS step_no,
        qty * 1.0                              AS qty          -- force REAL
    FROM monthly_sales
    WHERE product_id IN (4160, 7790)
      AND mth BETWEEN '2016-01-01' AND '2018-12-31'
),
weights AS (          -- give weight 1 to steps 7‑30, otherwise 0
    SELECT
        product_id,
        step_no,
        qty,
        CASE WHEN step_no BETWEEN 7 AND 30 THEN 1.0 ELSE 0.0 END AS w,
        step_no * 1.0 AS x
    FROM base
),
stats AS (            -- pre‑calculate the weighted sums needed for β‑coefficients
    SELECT
        product_id,
        SUM(w)               AS sw,
        SUM(w * x)           AS swx,
        SUM(w * qty)         AS swy,
        SUM(w * x * x)       AS swxx,
        SUM(w * x * qty)     AS swxy
    FROM weights
    GROUP BY product_id
),
coeff AS (            -- slope (β1) and intercept (β0)
    SELECT
        product_id,
        CASE
            WHEN (swxx - (swx * swx) / sw) = 0 THEN 0
            ELSE (swxy - (swx * swy) / sw) / (swxx - (swx * swx) / sw)
        END                                 AS slope,
        (swy - ((swxy - (swx * swy) / sw) /
               NULLIF((swxx - (swx * swx) / sw),0)) * swx) / sw  AS intercept
    FROM stats
),
-- generate integers 25 … 36 (the 12 monthly time‑steps of 2018)
nums(n) AS (
    SELECT 25
    UNION ALL
    SELECT n + 1 FROM nums WHERE n < 36
),
forecast AS (
    SELECT
        c.product_id,
        n                                          AS step_no,
        (c.intercept + c.slope * n)                AS qty_forecast
    FROM coeff c
    CROSS JOIN nums
),
annual AS (
    SELECT
        product_id,
        SUM(qty_forecast) AS forecasted_annual_sales_2018
    FROM forecast
    GROUP BY product_id
)
SELECT
    product_id,
    ROUND(forecasted_annual_sales_2018, 4) AS forecasted_annual_sales_2018
FROM annual
ORDER BY product_id;