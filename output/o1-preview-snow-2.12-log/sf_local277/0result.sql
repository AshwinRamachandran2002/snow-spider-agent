WITH base_data AS (
    SELECT
        s."product_id",
        TO_DATE(s."mth", 'YYYY-MM-DD') AS "mth",
        s."qty",
        DATEDIFF(month, TO_DATE('2016-01-01', 'YYYY-MM-DD'), TO_DATE(s."mth", 'YYYY-MM-DD')) + 1 AS "time_step"
    FROM
        "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES" s
    WHERE
        s."product_id" IN (4160, 7790)
        AND s."mth" BETWEEN '2016-01-01' AND '2018-12-01'
),
cma_data AS (
    SELECT
        b.*,
        AVG(b."qty") OVER (
            PARTITION BY b."product_id"
            ORDER BY b."time_step"
            ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING
        ) AS "cma"
    FROM
        base_data b
),
ratio_data AS (
    SELECT
        c.*,
        CASE WHEN c."cma" = 0 THEN NULL ELSE c."qty" / c."cma" END AS "sales_to_cma_ratio"
    FROM
        cma_data c
),
seasonal_indices AS (
    SELECT
        r."product_id",
        (MOD(r."time_step" - 1, 12) + 1) AS "month_no",
        AVG(r."sales_to_cma_ratio") AS "seasonal_index"
    FROM
        ratio_data r
    WHERE
        r."time_step" BETWEEN 7 AND 30
    GROUP BY
        r."product_id",
        (MOD(r."time_step" - 1, 12) + 1)
),
deseasonalized_data AS (
    SELECT
        r.*,
        s."seasonal_index",
        CASE WHEN s."seasonal_index" = 0 THEN NULL ELSE r."qty" / s."seasonal_index" END AS "deseasonalized_qty"
    FROM
        ratio_data r
    LEFT JOIN
        seasonal_indices s
    ON
        r."product_id" = s."product_id"
        AND (MOD(r."time_step" - 1, 12) + 1) = s."month_no"
),
regression_sums AS (
    SELECT
        d."product_id",
        SUM(d."time_step" * d."deseasonalized_qty") AS "sum_xy",
        SUM(d."time_step") AS "sum_x",
        SUM(d."deseasonalized_qty") AS "sum_y",
        SUM(d."time_step" * d."time_step") AS "sum_xx",
        COUNT(*) AS "n"
    FROM
        deseasonalized_data d
    WHERE
        d."deseasonalized_qty" IS NOT NULL
    GROUP BY
        d."product_id"
),
regression_params AS (
    SELECT
        r."product_id",
        CASE WHEN (r."n" * r."sum_xx" - r."sum_x" * r."sum_x") = 0 THEN 0
            ELSE (r."n" * r."sum_xy" - r."sum_x" * r."sum_y") / (r."n" * r."sum_xx" - r."sum_x" * r."sum_x") END AS "slope",
        CASE WHEN r."n" = 0 THEN 0
            ELSE (r."sum_y" - ((CASE WHEN (r."n" * r."sum_xx" - r."sum_x" * r."sum_x") = 0 THEN 0
            ELSE (r."n" * r."sum_xy" - r."sum_x" * r."sum_y") / (r."n" * r."sum_xx" - r."sum_x" * r."sum_x") END) * r."sum_x")) / r."n" END AS "intercept"
    FROM
        regression_sums r
),
forecast_data AS (
    SELECT
        d."product_id",
        d."time_step",
        d."mth",
        d."qty",
        d."seasonal_index",
        rp."slope",
        rp."intercept",
        (rp."intercept" + rp."slope" * d."time_step") AS "trend_component",
        (rp."intercept" + rp."slope" * d."time_step") * d."seasonal_index" AS "forecast_qty"
    FROM
        deseasonalized_data d
    JOIN
        regression_params rp ON d."product_id" = rp."product_id"
    WHERE
        d."time_step" BETWEEN 25 AND 36
)
SELECT
    f."product_id",
    ROUND(SUM(f."forecast_qty"), 4) AS "average_forecasted_annual_sales_2018"
FROM
    forecast_data f
GROUP BY
    f."product_id"
ORDER BY
    f."product_id";