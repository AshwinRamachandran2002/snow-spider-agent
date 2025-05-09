WITH sales AS ( -------------------------------------------------
    SELECT
        "product_id",
        CAST("mth" AS DATE)  AS "mth",
        CAST("qty" AS FLOAT) AS "qty"
    FROM ORACLE_SQL.ORACLE_SQL.MONTHLY_SALES
    WHERE "product_id" IN (4160, 7790)
      AND CAST("mth" AS DATE) BETWEEN '2016-01-01' AND '2018-12-31'
), -------------------------------------------------------------
sales_with_step AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (PARTITION BY "product_id" ORDER BY "mth") AS "time_step",
        MONTH("mth")                                                 AS "month_no"
    FROM sales s
), -------------------------------------------------------------
cma_calc AS (
    SELECT
        sws.*,
        (
          AVG("qty") OVER (PARTITION BY "product_id"
                           ORDER BY "time_step"
                           ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING) +
          AVG("qty") OVER (PARTITION BY "product_id"
                           ORDER BY "time_step"
                           ROWS BETWEEN 6 PRECEDING AND 5 FOLLOWING)
        ) / 2 AS "cma"
    FROM sales_with_step sws
), -------------------------------------------------------------
ratio_window AS (
    SELECT *
    FROM cma_calc
    WHERE "time_step" BETWEEN 7 AND 30
      AND "cma" <> 0
), -------------------------------------------------------------
seasonality AS (
    SELECT
        "product_id",
        "month_no",
        AVG("qty" / NULLIF("cma",0)) AS "seasonal_index"
    FROM ratio_window
    GROUP BY "product_id", "month_no"
), -------------------------------------------------------------
deseasonalized AS (
    SELECT
        sws.*,
        si."seasonal_index",
        sws."qty" / NULLIF(si."seasonal_index",0) AS "deseason_qty"
    FROM sales_with_step sws
    JOIN seasonality si
      ON si."product_id" = sws."product_id"
     AND si."month_no"   = sws."month_no"
    WHERE si."seasonal_index" IS NOT NULL
      AND si."seasonal_index" <> 0
), -------------------------------------------------------------
trend_params AS (
    SELECT
        "product_id",
        REGR_SLOPE("deseason_qty", "time_step")     AS "slope",
        REGR_INTERCEPT("deseason_qty", "time_step") AS "intercept"
    FROM deseasonalized
    GROUP BY "product_id"
), -------------------------------------------------------------
forecast_2018 AS (
    SELECT
        d."product_id",
        d."mth",
        (tp."intercept" + tp."slope" * d."time_step")                       AS "base_forecast",
        d."seasonal_index",
        (tp."intercept" + tp."slope" * d."time_step") * d."seasonal_index"  AS "forecast_qty"
    FROM deseasonalized d
    JOIN trend_params tp
      ON tp."product_id" = d."product_id"
    WHERE d."mth" BETWEEN '2018-01-01' AND '2018-12-31'
), -------------------------------------------------------------
annual_product AS (
    SELECT
        "product_id",
        AVG("forecast_qty") AS "avg_forecast_annual"
    FROM forecast_2018
    GROUP BY "product_id"
), -------------------------------------------------------------
overall AS (
    SELECT
        AVG("avg_forecast_annual") AS "average_forecast_annual_sales_2018"
    FROM annual_product
)
SELECT *
FROM overall;