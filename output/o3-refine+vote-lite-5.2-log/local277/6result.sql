WITH
/* 1. 36 months of historical sales, Jan‑2016 … Dec‑2018 (t = 1 … 36) */
hist AS (
    SELECT
        product_id,
        mth,
        qty,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY mth
        )                     AS t
    FROM monthly_sales
    WHERE product_id IN (4160, 7790)
      AND mth >= '2016-01-01'
      AND mth <  DATE('2016-01-01', '+36 months')
),
/* 2. seasonality weighting: double weight for steps 7 … 30            */
w_hist AS (
    SELECT
        product_id,
        t,
        qty,
        CASE WHEN t BETWEEN 7 AND 30 THEN 2.0 ELSE 1.0 END AS w
    FROM hist
),
/* 3. pre‑aggregate components needed for weighted least‑squares       */
stats AS (
    SELECT
        product_id,
        SUM(w)             AS sw,          -- Σw
        SUM(w*t)           AS swt,         -- Σwt
        SUM(w*t*t)         AS swt2,        -- Σwt²
        SUM(w*qty)         AS swy,         -- Σwy
        SUM(w*t*qty)       AS swty         -- Σwty
    FROM w_hist
    GROUP BY product_id
),
/* 4. regression coefficients: qtŷ = a + b·t                          */
coeff AS (
    SELECT
        product_id,
        (sw * swty - swt * swy) /
        (sw * swt2 - swt * swt)                           AS b,   -- slope
        (swy - ((sw * swty - swt * swy) /
               (sw * swt2 - swt * swt)) * swt) / sw       AS a    -- intercept
    FROM stats
),
/* 5. list of forecast months t = 25 … 36  (Jan‑2018 … Dec‑2018)       */
months AS (
    WITH RECURSIVE seq(t) AS (
        SELECT 25
        UNION ALL
        SELECT t+1 FROM seq WHERE t < 36
    )
    SELECT t FROM seq
),
/* 6. monthly forecasts for 2018                                       */
forecast AS (
    SELECT
        c.product_id,
        m.t,
        c.a + c.b * m.t               AS qty_forecast
    FROM coeff  c
    CROSS JOIN months m
),
/* 7. annual total per product                                         */
annual_forecast AS (
    SELECT
        product_id,
        SUM(qty_forecast)  AS forecast_2018
    FROM forecast
    GROUP BY product_id
)
/* 8. required result: average forecasted annual sales (2018)          */
SELECT
    AVG(forecast_2018)  AS avg_forecasted_annual_sales_2018
FROM annual_forecast;