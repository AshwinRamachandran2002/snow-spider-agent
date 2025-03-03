WITH sales_data AS (
    SELECT 
        ms.product_id,
        ms.mth,
        ms.qty,
        ((CAST(strftime('%Y', ms.mth) AS INTEGER) - 2016) * 12 + CAST(strftime('%m', ms.mth) AS INTEGER)) AS time_step,
        CAST(strftime('%m', ms.mth) AS INTEGER) AS month_num
    FROM "monthly_sales" ms
    WHERE ms.product_id IN (4160, 7790)
      AND ms.mth BETWEEN '2016-01-01' AND '2018-12-01'
),
seasonal_indices AS (
    SELECT 
        product_id,
        month_num,
        AVG(qty) AS avg_qty
    FROM sales_data
    WHERE time_step BETWEEN 7 AND 30
    GROUP BY product_id, month_num
),
overall_avg AS (
    SELECT 
        product_id,
        AVG(qty) AS overall_avg_qty
    FROM sales_data
    WHERE time_step BETWEEN 7 AND 30
    GROUP BY product_id
),
seasonality_factors AS (
    SELECT 
        si.product_id,
        si.month_num,
        si.avg_qty / oa.overall_avg_qty AS seasonality_index
    FROM seasonal_indices si
    JOIN overall_avg oa ON si.product_id = oa.product_id
),
adjusted_sales AS (
    SELECT 
        sd.product_id,
        sd.time_step,
        sd.qty / sf.seasonality_index AS deseasonalized_qty
    FROM sales_data sd
    JOIN seasonality_factors sf ON sd.product_id = sf.product_id AND sd.month_num = sf.month_num
),
regression_sums AS (
    SELECT 
        product_id,
        COUNT(*) AS n,
        SUM(time_step) AS sum_x,
        SUM(deseasonalized_qty) AS sum_y,
        SUM(time_step * time_step) AS sum_xx,
        SUM(time_step * deseasonalized_qty) AS sum_xy
    FROM adjusted_sales
    GROUP BY product_id
),
regression_params AS (
    SELECT 
        product_id,
        (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x) AS slope,
        (sum_y - ((n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x)) * sum_x) / n AS intercept
    FROM regression_sums
),
forecasts AS (
    SELECT 
        rp.product_id,
        ts.time_step,
        rp.slope * ts.time_step + rp.intercept AS forecasted_deseasonalized_qty,
        sf.seasonality_index,
        (rp.slope * ts.time_step + rp.intercept) * sf.seasonality_index AS forecasted_qty
    FROM (
        SELECT DISTINCT time_step,
               ((time_step - 1) % 12) + 1 AS month_num
        FROM sales_data
        WHERE time_step BETWEEN 25 AND 36
    ) AS ts
    JOIN regression_params rp ON 1=1
    JOIN seasonality_factors sf ON rp.product_id = sf.product_id AND ts.month_num = sf.month_num
    WHERE rp.product_id IN (4160, 7790)
),
annual_forecast AS (
    SELECT 
        product_id,
        SUM(forecasted_qty) AS average_forecasted_annual_sales
    FROM forecasts
    GROUP BY product_id
)
SELECT 
    product_id AS "Product ID",
    ROUND(average_forecasted_annual_sales, 4) AS "Average Forecasted Annual Sales (2018)"
FROM annual_forecast;