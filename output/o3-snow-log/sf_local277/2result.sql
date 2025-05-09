/*--------------------------------------------------------------------
  Average forecasted annual sales for products 4160 and 7790 in 2018
--------------------------------------------------------------------*/
WITH sales AS (   -- raw monthly sales in the first 36 months (Jan-2016 .. Dec-2018)
    SELECT 
        "product_id",
        TO_DATE("mth")            AS mth_date,
        "qty"
    FROM ORACLE_SQL.ORACLE_SQL."MONTHLY_SALES"
    WHERE "product_id" IN (4160, 7790)
      AND TO_DATE("mth") >= '2016-01-01'
      AND TO_DATE("mth") <  '2019-01-01'
), numbered AS (  -- give each month a time-step (t = 1 .. 36)
    SELECT
        s.*,
        DENSE_RANK() OVER (PARTITION BY "product_id" ORDER BY mth_date) AS t
    FROM sales s
), cma_calc AS (  -- centred 12-month moving average & Sales-to-CMA ratio
    SELECT
        n.*,
        (
          AVG("qty") OVER (PARTITION BY "product_id" ORDER BY t 
                ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING)
        + AVG("qty") OVER (PARTITION BY "product_id" ORDER BY t 
                ROWS BETWEEN 6 PRECEDING AND 5 FOLLOWING)
        ) / 2                                             AS cma,
        "qty" /
        NULLIF((
          AVG("qty") OVER (PARTITION BY "product_id" ORDER BY t 
                ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING)
        + AVG("qty") OVER (PARTITION BY "product_id" ORDER BY t 
                ROWS BETWEEN 6 PRECEDING AND 5 FOLLOWING)
        ) / 2 , 0)                                        AS ratio
    FROM numbered n
), season_sample AS (   -- take ratios only from time-steps 7 .. 30
    SELECT
        "product_id",
        EXTRACT(month FROM mth_date) AS month_no,
        ratio
    FROM cma_calc
    WHERE t BETWEEN 7 AND 30
), season_factor AS (    -- average ratio → seasonality factor per month
    SELECT
        "product_id",
        month_no,
        AVG(ratio) AS season_factor
    FROM season_sample
    GROUP BY "product_id", month_no
), deseason AS (         -- deseasonalise original series
    SELECT
        n."product_id",
        n.t,
        n.mth_date,
        n."qty",
        sf.season_factor,
        n."qty" / NULLIF(sf.season_factor,0) AS adj_qty
    FROM numbered n
    LEFT JOIN season_factor sf
      ON n."product_id" = sf."product_id"
     AND EXTRACT(month FROM n.mth_date) = sf.month_no
), trend AS (            -- weighted (deseasonalised) linear regression
    SELECT
        "product_id",
        REGR_SLOPE(adj_qty, t)      AS slope,
        REGR_INTERCEPT(adj_qty, t)  AS intercept
    FROM deseason
    GROUP BY "product_id"
), forecast AS (         -- re-apply seasonality to 2018 trend forecasts
    SELECT
        d."product_id",
        d.mth_date,
        (tr.intercept + tr.slope * d.t)                    AS forecast_adj,
        COALESCE(sf.season_factor,1)                      AS season_factor,
        (tr.intercept + tr.slope * d.t) * COALESCE(sf.season_factor,1) 
                                                          AS forecast_qty
    FROM deseason d
    JOIN trend tr
      ON d."product_id" = tr."product_id"
    LEFT JOIN season_factor sf
      ON d."product_id" = sf."product_id"
     AND EXTRACT(month FROM d.mth_date) = sf.month_no
    WHERE d.mth_date BETWEEN '2018-01-01' AND '2018-12-31'
), annual_totals AS (    -- annual forecast per product
    SELECT
        "product_id",
        SUM(forecast_qty) AS annual_forecast_2018
    FROM forecast
    GROUP BY "product_id"
)
SELECT 
    AVG(annual_forecast_2018) AS avg_annual_forecast_sales_2018
FROM annual_totals;