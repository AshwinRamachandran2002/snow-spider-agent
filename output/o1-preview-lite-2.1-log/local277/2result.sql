WITH sales_data AS (
    SELECT 
        product_id, 
        mth, 
        qty,
        ((strftime('%Y', mth) - 2016) * 12 + (strftime('%m', mth) - 1) + 1) AS time_step
    FROM monthly_sales
    WHERE product_id IN (4160, 7790) 
      AND mth >= '2016-01-01' 
      AND mth < date('2016-01-01', '+36 months')
),
adjusted_sales AS (
    SELECT 
        product_id,
        mth,
        qty,
        time_step,
        CASE 
            WHEN time_step BETWEEN 7 AND 30 THEN qty  -- Adjust for seasonality during time steps 7 to 30
            ELSE qty  -- No adjustment specified, so qty remains the same
        END AS adjusted_qty
    FROM sales_data
),
regression_data AS (
    SELECT 
        product_id,
        SUM(time_step * adjusted_qty) AS sum_xy,
        SUM(time_step) AS sum_x,
        SUM(adjusted_qty) AS sum_y,
        SUM(time_step * time_step) AS sum_xx,
        COUNT(*) AS n
    FROM adjusted_sales
    GROUP BY product_id
),
regression_coefficients AS (
    SELECT
        product_id,
        (n * sum_xy - sum_x * sum_y) * 1.0 / (n * sum_xx - sum_x * sum_x) AS slope,
        (sum_y * sum_xx - sum_x * sum_xy) * 1.0 / (n * sum_xx - sum_x * sum_x) AS intercept
    FROM regression_data
),
forecast_2018 AS (
    SELECT
        product_id,
        SUM(predicted_qty) AS forecasted_annual_sales_2018
    FROM (
        SELECT
            sd.product_id,
            sd.mth,
            rc.slope * sd.time_step + rc.intercept AS predicted_qty
        FROM sales_data sd
        JOIN regression_coefficients rc ON sd.product_id = rc.product_id
        WHERE sd.mth >= '2018-01-01' AND sd.mth < '2019-01-01'
    )
    GROUP BY product_id
)
SELECT 
    product_id AS Product_ID, 
    ROUND(forecasted_annual_sales_2018, 4) AS Average_Forecasted_Annual_Sales_2018
FROM forecast_2018;