/*------------------------------------------------------
  Forecast 2018 annual sales (average of the two products)
  – Products : 4160  &  7790
  – Training : first 36 months  (Jan-2016 … Dec-2018)
  – Regression : simple (weights = 1)
  – Seasonality factors derived from months 7-30
                   (Jul-2016 … Jun-2018)
------------------------------------------------------*/
WITH ordered AS (                 -- add running month index & month-of-year
    SELECT  product_id,
            mth,
            qty,
            ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY mth) AS idx,
            CAST(substr(mth,6,2) AS INTEGER)                   AS mon
    FROM    monthly_sales
    WHERE   product_id IN (4160,7790)
      AND   mth BETWEEN '2016-01-01' AND '2018-12-01'
),
-- ---------- ordinary-least-squares regression coefficients ----------
reg_stats AS (
    SELECT  product_id,
            COUNT(*)                       AS n,
            SUM(idx)                       AS sx,
            SUM(qty)                       AS sy,
            SUM(idx*idx)                  AS sx2,
            SUM(idx*qty)                  AS sxy
    FROM    ordered
    GROUP BY product_id
),
reg_coef AS (
    SELECT  product_id,
            -- slope  (β1)
            (n*sxy - sx*sy)*1.0 / (n*sx2 - sx*sx)          AS slope,
            -- intercept  (β0)
            (sy - ((n*sxy - sx*sy)*1.0 / (n*sx2 - sx*sx))*sx)*1.0 / n AS intercept
    FROM    reg_stats
),
-- ---------- seasonality (window idx 7-30) ----------
season_mon_avg AS (
    SELECT  product_id,
            mon,
            AVG(qty) AS mon_avg
    FROM    ordered
    WHERE   idx BETWEEN 7 AND 30
    GROUP BY product_id, mon
),
season_overall AS (
    SELECT  product_id,
            AVG(qty) AS overall_avg
    FROM    ordered
    WHERE   idx BETWEEN 7 AND 30
    GROUP BY product_id
),
seasonality AS (
    SELECT  m.product_id,
            m.mon,
            m.mon_avg * 1.0 / o.overall_avg AS factor
    FROM    season_mon_avg m
    JOIN    season_overall o
          ON o.product_id = m.product_id
),
-- ---------- build 2018 forecast (idx 25-36) ----------
forecast_2018 AS (
    SELECT  o.product_id,
            o.idx,
            (c.intercept + c.slope * o.idx)                AS base_pred,
            COALESCE(s.factor,1.0)                         AS seas_fac,
            (c.intercept + c.slope * o.idx) * COALESCE(s.factor,1.0)
                                                          AS fcast_qty
    FROM    ordered o
    JOIN    reg_coef   c ON c.product_id = o.product_id
    LEFT JOIN seasonality s
           ON s.product_id = o.product_id
          AND s.mon       = o.mon
    WHERE   o.idx BETWEEN 25 AND 36                       -- Jan-2018 … Dec-2018
),
annual_forecast AS (
    SELECT  product_id,
            SUM(fcast_qty) AS annual_qty
    FROM    forecast_2018
    GROUP BY product_id
)
SELECT  ROUND(AVG(annual_qty),4) AS avg_forecast_2018
FROM    annual_forecast;