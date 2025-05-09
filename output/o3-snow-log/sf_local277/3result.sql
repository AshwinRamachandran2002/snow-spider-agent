/* ------------------------------------------------------------
   Forecast 2018 annual sales for products 4160 and 7790
   – Monthly data from Jan-2016 (36 months in total)
   – Seasonality-adjusted centred moving average
   – Use months 7-30 as weighted-regression training set
   – Return the average of both products’ 2018 forecasts
----------------------------------------------------------------*/
WITH months AS (      -- 36 consecutive months starting 2016-01-01
    SELECT
        SEQ4() + 1                                AS "time_step",     -- 1 … 36
        DATEADD(month, SEQ4(), '2016-01-01')::DATE AS "mth"
    FROM TABLE(GENERATOR(ROWCOUNT => 36))
),
products AS (         -- the two products we are interested in
    SELECT COLUMN1::NUMBER AS "product_id"
    FROM (VALUES (4160), (7790))
),
sales_base AS (       -- complete month grid + actual sales (missing ⇒ 0)
    SELECT
        p."product_id",
        m."time_step",
        m."mth",
        COALESCE(ms."qty", 0) AS "qty"
    FROM products p
    JOIN months  m
    LEFT JOIN ORACLE_SQL.ORACLE_SQL."MONTHLY_SALES" ms
           ON ms."product_id" = p."product_id"
          AND ms."mth"        = TO_CHAR(m."mth", 'YYYY-MM-DD')
),
cma_calc AS (         -- centred moving average (two overlapping 12-month windows)
    SELECT
        "product_id",
        "time_step",
        "mth",
        "qty",
        ( AVG("qty") OVER (PARTITION BY "product_id"
                           ORDER BY "time_step"
                           ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING)
        + AVG("qty") OVER (PARTITION BY "product_id"
                           ORDER BY "time_step"
                           ROWS BETWEEN 6 PRECEDING AND 5 FOLLOWING) ) / 2  AS "cma"
    FROM sales_base
),
ratio_calc AS (       -- sales-to-CMA ratio (used as weight)
    SELECT
        *,
        CASE WHEN "cma" IS NULL OR "cma" = 0 THEN NULL
             ELSE "qty" / "cma"
        END AS "weight"
    FROM cma_calc
),
train AS (            -- restrict to time-steps 7-30 for model fitting
    SELECT *
    FROM   ratio_calc
    WHERE  "time_step" BETWEEN 7 AND 30
      AND  "weight" IS NOT NULL
),
agg AS (              -- prepare weighted sums for each product
    SELECT
        "product_id",
        SUM("weight"                         ) AS "sum_w",
        SUM("weight" * "time_step"           ) AS "sum_wx",
        SUM("weight" * "qty"                 ) AS "sum_wy",
        SUM("weight" * "time_step" * "time_step") AS "sum_wx2",
        SUM("weight" * "time_step" * "qty"   ) AS "sum_wxy"
    FROM train
    GROUP BY "product_id"
),
params AS (           -- derive weighted-OLS slope & intercept
    SELECT
        "product_id",
        /* weighted means */
        "sum_wx" / "sum_w" AS "wxbar",
        "sum_wy" / "sum_w" AS "wybar",
        /* slope */
        ("sum_wxy" - ("sum_wx" * "sum_wy") / "sum_w")
        /
        ("sum_wx2" - ("sum_wx" * "sum_wx") / "sum_w")          AS "slope",
        /* intercept */
        "wybar" -
        ( ("sum_wxy" - ("sum_wx" * "sum_wy") / "sum_w")
          /
          ("sum_wx2" - ("sum_wx" * "sum_wx") / "sum_w") ) *
        "wxbar"                                                AS "intercept"
    FROM agg
),
forecast_months AS (  -- calculate forecasts for 2018 (time-steps 25-36)
    SELECT
        s."product_id",
        s."time_step",
        s."mth",
        p."intercept" + p."slope" * s."time_step" AS "forecast_qty"
    FROM sales_base s
    JOIN params     p  ON p."product_id" = s."product_id"
    WHERE s."time_step" BETWEEN 25 AND 36
),
annual_forecast AS (  -- sum the 12 monthly forecasts per product
    SELECT
        "product_id",
        SUM("forecast_qty") AS "annual_forecast_qty"
    FROM forecast_months
    GROUP BY "product_id"
)
SELECT
    AVG("annual_forecast_qty") AS "avg_annual_forecast_qty_2018"
FROM annual_forecast;