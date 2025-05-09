WITH sales_data AS (
    SELECT
        ms."product_id",
        ms."mth",
        ms."qty",
        ROW_NUMBER() OVER (PARTITION BY ms."product_id" ORDER BY TO_DATE(ms."mth", 'YYYY-MM-DD')) AS "time_step",
        EXTRACT(MONTH FROM TO_DATE(ms."mth", 'YYYY-MM-DD')) AS "month_in_year"
    FROM
        "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES" ms
    WHERE
        ms."product_id" IN (4160, 7790)
        AND ms."mth" >= '2016-01-01'
        AND ms."mth" <= '2018-12-01'
),
cma_data AS (
    SELECT
        sd.*,
        SUM(sd."qty") OVER (
            PARTITION BY sd."product_id"
            ORDER BY sd."time_step"
            ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING
        ) / 12 AS "avg1",
        SUM(sd."qty") OVER (
            PARTITION BY sd."product_id"
            ORDER BY sd."time_step"
            ROWS BETWEEN 6 PRECEDING AND 5 FOLLOWING
        ) / 12 AS "avg2"
    FROM
        sales_data sd
),
ratio_data AS (
    SELECT
        cd.*,
        CASE WHEN cd."time_step" BETWEEN 7 AND 30 THEN
            (cd."avg1" + cd."avg2") / 2
        ELSE NULL END AS "CMA",
        CASE WHEN cd."time_step" BETWEEN 7 AND 30 AND ((cd."avg1" + cd."avg2") / 2) <> 0 THEN
            cd."qty" / ((cd."avg1" + cd."avg2") / 2)
        ELSE NULL END AS "ratio"
    FROM
        cma_data cd
),
seasonal_indices AS (
    SELECT
        rd."product_id",
        rd."month_in_year",
        AVG(rd."ratio") AS "seasonal_index"
    FROM
        ratio_data rd
    WHERE
        rd."time_step" BETWEEN 7 AND 30
        AND rd."ratio" IS NOT NULL
    GROUP BY
        rd."product_id",
        rd."month_in_year"
),
deseasonalized_sales AS (
    SELECT
        sd."product_id",
        sd."time_step",
        sd."mth",
        sd."qty",
        sd."month_in_year",
        sd."qty" / NULLIF(si."seasonal_index", 0) AS "deseasonalized_qty"
    FROM
        sales_data sd
    JOIN
        seasonal_indices si
    ON
        sd."product_id" = si."product_id"
        AND sd."month_in_year" = si."month_in_year"
),
regression_data AS (
    SELECT
        ds."product_id",
        COUNT(*) AS "n",
        SUM(ds."time_step") AS "sum_time",
        SUM(ds."deseasonalized_qty") AS "sum_qty",
        SUM(ds."time_step" * ds."deseasonalized_qty") AS "sum_time_qty",
        SUM(ds."time_step" * ds."time_step") AS "sum_time_sq"
    FROM
        deseasonalized_sales ds
    WHERE
        ds."deseasonalized_qty" IS NOT NULL
    GROUP BY
        ds."product_id"
),
regression_coefficients AS (
    SELECT
        rd."product_id",
        CASE WHEN rd."n" * rd."sum_time_sq" - rd."sum_time" * rd."sum_time" <> 0 THEN
            (rd."n" * rd."sum_time_qty" - rd."sum_time" * rd."sum_qty") /
            (rd."n" * rd."sum_time_sq" - rd."sum_time" * rd."sum_time")
        ELSE NULL END AS "slope",
        CASE WHEN rd."n" * rd."sum_time_sq" - rd."sum_time" * rd."sum_time" <> 0 THEN
            (rd."sum_qty" * rd."sum_time_sq" - rd."sum_time" * rd."sum_time_qty") /
            (rd."n" * rd."sum_time_sq" - rd."sum_time" * rd."sum_time")
        ELSE NULL END AS "intercept"
    FROM
        regression_data rd
),
forecast_sales AS (
    SELECT
        ds."product_id",
        ds."time_step",
        ds."mth",
        ds."qty",
        ds."deseasonalized_qty",
        rc."slope",
        rc."intercept",
        (rc."slope" * ds."time_step" + rc."intercept") * si."seasonal_index" AS "forecast_qty"
    FROM
        deseasonalized_sales ds
    JOIN
        regression_coefficients rc
    ON
        ds."product_id" = rc."product_id"
    JOIN
        seasonal_indices si
    ON
        ds."product_id" = si."product_id"
        AND ds."month_in_year" = si."month_in_year"
    WHERE
        ds."time_step" BETWEEN 25 AND 36
        AND rc."slope" IS NOT NULL
        AND rc."intercept" IS NOT NULL
        AND si."seasonal_index" IS NOT NULL
)
SELECT
    fs."product_id" AS "Product_ID",
    ROUND(SUM(fs."forecast_qty"), 4) AS "Average_Forecasted_Annual_Sales_2018"
FROM
    forecast_sales fs
GROUP BY
    fs."product_id";