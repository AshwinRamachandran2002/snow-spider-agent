/*--------------------------------------------------------------------
  Forecast average annual sales for products 4160 and 7790 (year 2018)
  • Uses first 36 months of data (Jan-2016 → Dec-2018)
  • Builds centred 12-month moving average (CMA)
  • Derives seasonal factors from time-steps 7-30
  • Fits a weighted (CMA-weighted) linear regression trend
  • Forecasts each month of 2018    forecast = (trend • seasonal factor)
  • Returns the average of the two product-level 2018 forecasts
--------------------------------------------------------------------*/
WITH sales AS (           -- restrict to the needed products / months
    SELECT
        "product_id",
        TO_DATE("mth")      AS "mth",
        "qty"
    FROM ORACLE_SQL.ORACLE_SQL."MONTHLY_SALES"
    WHERE "product_id" IN (4160, 7790)
      AND TO_DATE("mth") BETWEEN TO_DATE('2016-01-01') AND TO_DATE('2018-12-31')
),
ts AS (                    -- create a time index 1-36 inside each product
    SELECT
        "product_id",
        "mth",
        "qty",
        ROW_NUMBER() OVER (PARTITION BY "product_id" ORDER BY "mth") AS t
    FROM sales
),
cma_calc AS (              -- centred 12-month moving average
    SELECT
        t1."product_id",
        t1."mth",
        t1.t,
        t1."qty",
        (
            AVG(t1."qty") OVER (PARTITION BY t1."product_id"
                                 ORDER BY t1."mth"
                                 ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING)
          + AVG(t1."qty") OVER (PARTITION BY t1."product_id"
                                 ORDER BY t1."mth"
                                 ROWS BETWEEN 6 PRECEDING AND 5 FOLLOWING)
        ) / 2                                                  AS cma
    FROM ts t1
),
seasonality AS (           -- average Sales/CMA for t = 7-30 ⇒ seasonal factor
    SELECT
        "product_id",
        MONTH("mth")                              AS month_no,
        AVG("qty" / cma)                          AS seasonal_factor
    FROM cma_calc
    WHERE t BETWEEN 7 AND 30
      AND cma IS NOT NULL
    GROUP BY "product_id", month_no
),
trend_source AS (          -- data set used for trend estimation
    SELECT
        "product_id",
        t,
        "qty",
        cma
    FROM cma_calc
    WHERE cma IS NOT NULL
),
trend_stats AS (           -- build weighted-regression aggregates
    SELECT
        "product_id",
        SUM(cma)               AS sw,      -- Σw
        SUM(cma * t)           AS swx,     -- Σw·x
        SUM(cma * t * t)       AS swx2,    -- Σw·x²
        SUM(cma * "qty")       AS swy,     -- Σw·y
        SUM(cma * t * "qty")   AS swxy     -- Σw·x·y
    FROM trend_source
    GROUP BY "product_id"
),
trend_params AS (          -- slope & intercept of weighted linear trend
    SELECT
        "product_id",
        (sw * swxy - swx * swy)
        / NULLIF(sw * swx2 - swx * swx, 0)                         AS slope,
        (swy - ((sw * swxy - swx * swy)
                / NULLIF(sw * swx2 - swx * swx, 0)) * swx) / sw    AS intercept
    FROM trend_stats
),
forecast_mth AS (          -- monthly forecasts for calendar-year 2018
    SELECT
        c."product_id",
        c."mth",
        c.t,
        p.intercept + p.slope * c.t                      AS trend_value,
        s.seasonal_factor,
        (p.intercept + p.slope * c.t) * s.seasonal_factor AS forecast_qty
    FROM cma_calc            c
    JOIN trend_params        p ON p."product_id" = c."product_id"
    JOIN seasonality         s ON s."product_id" = c."product_id"
                               AND s.month_no = MONTH(c."mth")
    WHERE c."mth" BETWEEN TO_DATE('2018-01-01') AND TO_DATE('2018-12-31')
),
annual_forecast AS (       -- sum monthly forecasts → annual per product
    SELECT
        "product_id",
        SUM(forecast_qty) AS annual_forecast_qty
    FROM forecast_mth
    GROUP BY "product_id"
),
avg_forecast AS (          -- average of the two products
    SELECT
        AVG(annual_forecast_qty) AS avg_annual_forecast_qty2018
    FROM annual_forecast
)
SELECT *
FROM avg_forecast;