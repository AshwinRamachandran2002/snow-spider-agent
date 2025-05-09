WITH base_data AS (
    SELECT 
        ms."product_id", 
        ms."qty", 
        ms."mth", 
        ROW_NUMBER() OVER (PARTITION BY ms."product_id" ORDER BY ms."mth") AS "time_step"
    FROM "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES" ms
    WHERE ms."product_id" IN (4160, 7790) AND ms."mth" BETWEEN '2016-01-01' AND '2018-12-01'
),
cma_data AS (
    SELECT 
        bd.*,
        CASE WHEN bd."time_step" BETWEEN 7 AND 30 THEN
            ((AVG(bd."qty") OVER (PARTITION BY bd."product_id" ORDER BY bd."time_step" ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING)
            + AVG(bd."qty") OVER (PARTITION BY bd."product_id" ORDER BY bd."time_step" ROWS BETWEEN 6 PRECEDING AND 5 FOLLOWING)) / 2)
        ELSE NULL END AS "cma"
    FROM base_data bd
),
ratio_data AS (
    SELECT 
        cd.*,
        CASE WHEN cd."time_step" BETWEEN 7 AND 30 AND cd."cma" <> 0 THEN
            cd."qty" / cd."cma"
        ELSE NULL END AS "ratio"
    FROM cma_data cd
),
seasonal_indices AS (
    SELECT 
        cd."product_id",
        EXTRACT(MONTH FROM TO_DATE(cd."mth", 'YYYY-MM-DD')) AS "month",
        AVG(cd."ratio") AS "seasonal_index"
    FROM ratio_data cd
    WHERE cd."time_step" BETWEEN 7 AND 30 AND cd."ratio" IS NOT NULL
    GROUP BY cd."product_id", EXTRACT(MONTH FROM TO_DATE(cd."mth", 'YYYY-MM-DD'))
),
adjusted_data AS (
    SELECT 
        bd.*,
        si."seasonal_index",
        CASE WHEN si."seasonal_index" <> 0 THEN bd."qty" / si."seasonal_index" ELSE NULL END AS "adjusted_qty"
    FROM base_data bd
    JOIN seasonal_indices si
        ON bd."product_id" = si."product_id"
        AND EXTRACT(MONTH FROM TO_DATE(bd."mth", 'YYYY-MM-DD')) = si."month"
    WHERE si."seasonal_index" IS NOT NULL
),
regression_sums AS (
    SELECT 
        ad."product_id",
        COUNT(ad."time_step") AS n,
        SUM(ad."time_step") AS sum_x,
        SUM(ad."adjusted_qty") AS sum_y,
        SUM(ad."time_step" * ad."adjusted_qty") AS sum_xy,
        SUM(ad."time_step" * ad."time_step") AS sum_xx
    FROM adjusted_data ad
    WHERE ad."adjusted_qty" IS NOT NULL
    GROUP BY ad."product_id"
),
regression_params AS (
    SELECT
        rs."product_id",
        rs.n,
        rs.sum_x,
        rs.sum_y,
        rs.sum_xy,
        rs.sum_xx,
        CASE WHEN (rs.n * rs.sum_xx - rs.sum_x * rs.sum_x) <> 0 THEN
            (rs.n * rs.sum_xy - rs.sum_x * rs.sum_y) / (rs.n * rs.sum_xx - rs.sum_x * rs.sum_x)
        ELSE 0 END AS slope,
        CASE WHEN rs.n <> 0 THEN
            (rs.sum_y - ((CASE WHEN (rs.n * rs.sum_xx - rs.sum_x * rs.sum_x) <> 0 THEN
                (rs.n * rs.sum_xy - rs.sum_x * rs.sum_y) / (rs.n * rs.sum_xx - rs.sum_x * rs.sum_x)
            ELSE 0 END) * rs.sum_x)) / rs.n
        ELSE 0 END AS intercept
    FROM regression_sums rs
),
forecast AS (
    SELECT
        bd."product_id",
        bd."time_step",
        bd."mth",
        (rp.intercept + rp.slope * bd."time_step") AS "trend",
        si."seasonal_index",
        (rp.intercept + rp.slope * bd."time_step") * si."seasonal_index" AS "forecast_qty"
    FROM base_data bd
    JOIN regression_params rp ON bd."product_id" = rp."product_id"
    JOIN seasonal_indices si 
        ON bd."product_id" = si."product_id"
        AND EXTRACT(MONTH FROM TO_DATE(bd."mth", 'YYYY-MM-DD')) = si."month"
    WHERE bd."time_step" BETWEEN 25 AND 36
),
annual_forecast AS (
    SELECT 
        "product_id",
        ROUND(SUM("forecast_qty"), 4) AS "average_forecasted_annual_sales_2018"
    FROM forecast
    GROUP BY "product_id"
)
SELECT 
    "product_id",
    "average_forecasted_annual_sales_2018"
FROM annual_forecast
ORDER BY "product_id";