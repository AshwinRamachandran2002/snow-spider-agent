WITH sales_data AS (
    SELECT
        product_id,
        qty,
        (( (CAST(strftime('%Y', mth) AS INTEGER) - 2016) * 12 ) + CAST(strftime('%m', mth) AS INTEGER) ) AS time_step
    FROM
        monthly_sales
    WHERE
        product_id IN (4160, 7790)
        AND mth BETWEEN '2016-01-01' AND '2017-12-01'  -- Use data up to Dec 2017
),
seasonal_data AS (
    SELECT
        product_id,
        qty,
        time_step,
        CASE WHEN time_step BETWEEN 7 AND 30 THEN 1 ELSE 0 END AS seasonality
    FROM
        sales_data
),
weights AS (
    SELECT
        *,
        CASE WHEN seasonality = 1 THEN 2 ELSE 1 END AS weight  -- Apply seasonality adjustments
    FROM
        seasonal_data
),
stats AS (
    SELECT
        product_id,
        SUM(weight) AS n,
        SUM(weight * time_step) AS sum_x,
        SUM(weight * qty) AS sum_y,
        SUM(weight * time_step * qty) AS sum_xy,
        SUM(weight * time_step * time_step) AS sum_x2
    FROM
        weights
    GROUP BY
        product_id
),
coef AS (
    SELECT
        product_id,
        ( (n * sum_xy - sum_x * sum_y) * 1.0 ) / (n * sum_x2 - sum_x * sum_x) AS b,
        ( (sum_y * sum_x2 - sum_x * sum_xy) * 1.0 ) / (n * sum_x2 - sum_x * sum_x) AS a
    FROM
        stats
),
forecast AS (
    WITH RECURSIVE series(time_step) AS (
       SELECT 25  -- Forecasting time steps 25 to 36 (Jan to Dec 2018)
       UNION ALL
       SELECT time_step + 1 FROM series WHERE time_step < 36
    )
    SELECT
        s.product_id,
        series.time_step,
        s.a + s.b * series.time_step AS forecast_qty
    FROM
        coef s
        CROSS JOIN series
)
SELECT
    product_id,
    ROUND(SUM(forecast_qty), 4) AS "Average Forecasted Annual Sales (2018)"
FROM
    forecast
GROUP BY
    product_id;