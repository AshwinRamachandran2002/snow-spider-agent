/*--------------------------------------------------------------------
  Forecast average annual sales for products 4160 and 7790 in 2018
  – first 36 months of data (Jan-2016 … Dec-2018)
  – seasonality factors calculated from time steps 7-30
  – linear (weighted) regression for trend
--------------------------------------------------------------------*/
WITH
/* products of interest                                                */
product_list AS (
    SELECT 4160 AS product_id
    UNION ALL
    SELECT 7790 AS product_id
),
/* calendar for the first 36 months starting 2016-01-01                */
calendar AS (
    SELECT
        SEQ4() + 1                                              AS t ,           -- time index 1 … 36
        DATEADD(month, SEQ4(), '2016-01-01'::date)              AS mth           -- month start date
    FROM TABLE(GENERATOR(ROWCOUNT => 36))
),
/* raw sales from fact table                                           */
sales_raw AS (
    SELECT
        "product_id"       AS product_id,        -- rename to un-quoted so later refs work
        TO_DATE("mth")     AS mth_date,
        COALESCE("qty",0)  AS qty
    FROM ORACLE_SQL.ORACLE_SQL."MONTHLY_SALES"
    WHERE "product_id" IN (4160, 7790)
      AND TO_DATE("mth") BETWEEN '2016-01-01'::date AND '2018-12-31'::date
),
/* build complete 36-month panel, filling missing months with 0        */
sales AS (
    SELECT
        p.product_id,
        c.t,
        c.mth,
        COALESCE(sr.qty, 0) AS qty
    FROM product_list p
    JOIN calendar     c  ON 1=1
    LEFT JOIN sales_raw sr
           ON sr.product_id = p.product_id
          AND sr.mth_date   = c.mth
),
/* regression parameters (trend) per product                           */
regression AS (
    SELECT
        product_id,
        REGR_SLOPE(qty , t)      AS slope,
        REGR_INTERCEPT(qty , t)  AS intercept
    FROM sales
    GROUP BY product_id
),
/* centered moving averages for seasonality                            */
seasonality_base AS (
    SELECT
        s.*,
        AVG(qty) OVER (PARTITION BY product_id ORDER BY t
                       ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING) AS cma1,
        AVG(qty) OVER (PARTITION BY product_id ORDER BY t
                       ROWS BETWEEN 6 PRECEDING AND 5 FOLLOWING) AS cma2
    FROM sales s
),
/* seasonality factors from time steps 7-30                            */
seasonality AS (
    SELECT
        product_id,
        MONTH(mth)                              AS mon,
        AVG(qty / ((cma1 + cma2)/2))            AS seasonality_factor
    FROM seasonality_base
    WHERE t BETWEEN 7 AND 30
      AND cma1 IS NOT NULL
      AND cma2 IS NOT NULL
    GROUP BY product_id, MONTH(mth)
),
/* monthly forecasts for 2018                                          */
forecast_monthly AS (
    SELECT
        s.product_id,
        s.mth,
        (r.intercept + r.slope * s.t)                         AS trend_pred,
        se.seasonality_factor,
        (r.intercept + r.slope * s.t) * se.seasonality_factor AS forecast_qty
    FROM sales        s
    JOIN regression   r  ON r.product_id = s.product_id
    JOIN seasonality  se ON se.product_id = s.product_id
                        AND se.mon        = MONTH(s.mth)
    WHERE s.mth BETWEEN '2018-01-01'::date AND '2018-12-01'::date
),
/* annual forecast per product                                         */
forecast_annual AS (
    SELECT
        product_id,
        SUM(forecast_qty) AS annual_forecast_qty
    FROM forecast_monthly
    GROUP BY product_id
)
/* final answer                                                        */
SELECT
    AVG(annual_forecast_qty) AS avg_annual_forecast_2018
FROM forecast_annual;