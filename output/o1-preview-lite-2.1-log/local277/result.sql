WITH sales_data AS (
    SELECT
        product_id,
        mth,
        ((strftime('%Y', mth) - 2016) * 12 + (strftime('%m', mth) - 1) + 1) AS time_step,
        CAST(strftime('%m', mth) AS INTEGER) AS month_num,
        qty
    FROM monthly_sales
    WHERE
        product_id IN (4160, 7790)
        AND mth >= '2016-01-01'
        AND mth < '2019-01-01'
),
seasonal_avg AS (
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
        AVG(qty) AS avg_qty
    FROM sales_data
    WHERE time_step BETWEEN 7 AND 30
    GROUP BY product_id
),
seasonal_index AS (
    SELECT
        s.product_id,
        s.month_num,
        s.avg_qty / o.avg_qty AS seasonal_index
    FROM seasonal_avg s
    JOIN overall_avg o ON s.product_id = o.product_id
),
adjusted_sales AS (
    SELECT
        sd.product_id,
        sd.time_step,
        sd.qty / si.seasonal_index AS adjusted_qty
    FROM sales_data sd
    JOIN seasonal_index si ON sd.product_id = si.product_id AND sd.month_num = si.month_num
    WHERE sd.time_step BETWEEN 7 AND 30
),
stats AS (
    SELECT
        product_id,
        COUNT(*) AS n,
        SUM(time_step) AS sum_x,
        SUM(adjusted_qty) AS sum_y,
        SUM(time_step * adjusted_qty) AS sum_xy,
        SUM(time_step * time_step) AS sum_xx
    FROM adjusted_sales
    GROUP BY product_id
),
regression AS (
    SELECT
        product_id,
        (n * sum_xy - sum_x * sum_y) * 1.0 / (n * sum_xx - sum_x * sum_x) AS slope,
        (sum_y - ((n * sum_xy - sum_x * sum_y) * 1.0 / (n * sum_xx - sum_x * sum_x)) * sum_x) * 1.0 / n AS intercept
    FROM stats
),
forecast AS (
    SELECT
        r.product_id,
        sd.time_step,
        (r.slope * sd.time_step + r.intercept) * si.seasonal_index AS predicted_qty
    FROM regression r
    JOIN (
        SELECT product_id, time_step, month_num
        FROM sales_data
        WHERE time_step BETWEEN 25 AND 36
    ) sd ON r.product_id = sd.product_id
    JOIN seasonal_index si ON sd.product_id = si.product_id AND sd.month_num = si.month_num
)
SELECT
    product_id,
    ROUND(SUM(predicted_qty), 4) AS Average_Forecasted_Annual_Sales_2018
FROM forecast
GROUP BY product_id;