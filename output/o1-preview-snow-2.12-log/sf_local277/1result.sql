WITH time_steps AS (
    SELECT
        "mth",
        ROW_NUMBER() OVER (ORDER BY "mth") AS time_step
    FROM (
        SELECT DISTINCT "mth"
        FROM "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES"
        WHERE "mth" BETWEEN '2016-01-01' AND '2018-12-01'
    )
),
sales_data AS (
    SELECT
        s."product_id",
        s."mth",
        s."qty",
        ts.time_step
    FROM
        "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES" s
    JOIN
        time_steps ts
    ON
        s."mth" = ts."mth"
    WHERE
        s."product_id" IN (4160, 7790)
        AND s."mth" BETWEEN '2016-01-01' AND '2018-12-01'
),
sales_with_cma AS (
    SELECT
        sd.*,
        AVG(sd."qty") OVER (
            PARTITION BY sd."product_id"
            ORDER BY sd.time_step
            ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING
        ) AS cma1,
        AVG(sd."qty") OVER (
            PARTITION BY sd."product_id"
            ORDER BY sd.time_step
            ROWS BETWEEN 6 PRECEDING AND 5 FOLLOWING
        ) AS cma2
    FROM
        sales_data sd
),
sales_with_cma_avg AS (
    SELECT
        *,
        (cma1 + cma2) / 2 AS cma
    FROM
        sales_with_cma
),
sales_ratio AS (
    SELECT
        *,
        CASE WHEN cma <> 0 THEN "qty" / cma ELSE NULL END AS sales_to_cma_ratio
    FROM
        sales_with_cma_avg
),
seasonal_index AS (
    SELECT
        time_step,
        AVG(sales_to_cma_ratio) AS seasonal_index
    FROM
        sales_ratio
    WHERE
        time_step BETWEEN 7 AND 30
    GROUP BY
        time_step
),
deseasonalized_sales AS (
    SELECT
        sr."product_id",
        sr.time_step,
        sr."mth",
        sr."qty",
        sr.cma,
        sr.sales_to_cma_ratio,
        si.seasonal_index,
        CASE WHEN si.seasonal_index <> 0 THEN sr."qty" / si.seasonal_index ELSE NULL END AS deseasonalized_qty
    FROM
        sales_ratio sr
    JOIN
        seasonal_index si
    ON
        sr.time_step = si.time_step
),
regression_data AS (
    SELECT
        ds."product_id",
        ds.time_step,
        ds.deseasonalized_qty
    FROM
        deseasonalized_sales ds
    WHERE
        ds.time_step BETWEEN 7 AND 30
),
regression_params AS (
    SELECT
        "product_id",
        COUNT(*) AS n,
        SUM(time_step) AS sum_t,
        SUM(deseasonalized_qty) AS sum_x,
        SUM(time_step * deseasonalized_qty) AS sum_tx,
        SUM(time_step * time_step) AS sum_tt
    FROM
        regression_data
    GROUP BY
        "product_id"
),
regression_coefficients AS (
    SELECT
        rp."product_id",
        (rp.n * rp.sum_tx - rp.sum_t * rp.sum_x) / NULLIF(rp.n * rp.sum_tt - rp.sum_t * rp.sum_t, 0) AS slope,
        (rp.sum_x - ((rp.n * rp.sum_tx - rp.sum_t * rp.sum_x) / NULLIF(rp.n * rp.sum_tt - rp.sum_t * rp.sum_t, 0)) * rp.sum_t) / rp.n AS intercept
    FROM
        regression_params rp
),
forecast_deseasonalized AS (
    SELECT
        rc."product_id",
        t.time_step,
        (rc.slope * t.time_step) + rc.intercept AS forecast_deseasonalized_qty
    FROM
        regression_coefficients rc
    CROSS JOIN
        (SELECT DISTINCT time_step FROM sales_data WHERE time_step BETWEEN 25 AND 36) t
),
forecast_sales AS (
    SELECT
        fd."product_id",
        fd.time_step,
        fd.forecast_deseasonalized_qty * si.seasonal_index AS forecast_qty
    FROM
        forecast_deseasonalized fd
    JOIN
        seasonal_index si
    ON
        fd.time_step = si.time_step
),
average_forecasted_sales AS (
    SELECT
        "product_id",
        SUM(forecast_qty) AS average_forecasted_annual_sales_2018
    FROM
        forecast_sales
    GROUP BY
        "product_id"
)
SELECT
    "product_id",
    ROUND(average_forecasted_annual_sales_2018, 4) AS average_forecasted_annual_sales_2018
FROM
    average_forecasted_sales
ORDER BY
    "product_id";