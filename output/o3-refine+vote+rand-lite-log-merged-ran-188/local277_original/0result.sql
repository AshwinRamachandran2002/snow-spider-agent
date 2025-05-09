WITH
/* --- monthly time series (Jan‑2016 = step 1) ---------------------------- */
ts AS (
    SELECT
        product_id,
        qty,
        (CAST(substr(mth,1,4) AS INTEGER) - 2016) * 12
        + CAST(substr(mth,6,2) AS INTEGER)                AS time_step,   -- 1‑36
        CAST(substr(mth,6,2) AS INTEGER)                  AS mth_no
    FROM   monthly_sales
    WHERE  product_id IN (4160,7790)
      AND  mth BETWEEN '2016-01-01' AND '2018-12-01'
),
ts36 AS (                     -- only the first 36 monthly points
    SELECT * FROM ts
    WHERE  time_step BETWEEN 1 AND 36
),

/* --- seasonality: steps 7‑30 ------------------------------------------- */
season_base AS (              -- average per calendar‑month inside 7‑30
    SELECT product_id,
           mth_no,
           AVG(qty) AS avg_qty
    FROM   ts36
    WHERE  time_step BETWEEN 7 AND 30
    GROUP  BY product_id, mth_no
),
overall AS (                   -- grand average over steps 7‑30
    SELECT product_id,
           AVG(qty) AS overall_avg
    FROM   ts36
    WHERE  time_step BETWEEN 7 AND 30
    GROUP  BY product_id
),
season_factor AS (             -- seasonal index  (month / grand)
    SELECT sb.product_id,
           sb.mth_no,
           sb.avg_qty / o.overall_avg AS factor
    FROM   season_base sb
    JOIN   overall      o USING (product_id)
),

/* --- de‑seasonalise series --------------------------------------------- */
ts_adj AS (
    SELECT t.product_id,
           t.time_step,
           t.mth_no,
           t.qty,
           t.qty / COALESCE(sf.factor,1) AS adj_qty
    FROM   ts36 t
    LEFT   JOIN season_factor sf
           ON  sf.product_id = t.product_id
           AND sf.mth_no     = t.mth_no
),

/* --- weighted (time‑weighted) regression -------------------------------- */
stats AS (
    SELECT product_id,
           SUM(time_step)                        AS swx,
           SUM(time_step*time_step)              AS swx2,
           SUM(time_step*adj_qty)                AS swxy,
           SUM(adj_qty)                          AS swy,
           SUM(time_step)                        AS sw
    FROM   ts_adj
    GROUP  BY product_id
),
reg AS (      -- slope & intercept   (weight = time_step)
    SELECT
        product_id,
        CASE
            WHEN (swx2 - (swx*swx)/sw)=0 THEN 0
            ELSE (swxy - (swx*swy)/sw) / (swx2 - (swx*swx)/sw)
        END                                        AS slope,
        (swy - (CASE
                    WHEN (swx2 - (swx*swx)/sw)=0 THEN 0
                    ELSE (swxy - (swx*swy)/sw) / (swx2 - (swx*swx)/sw)
                 END) * swx) / sw                  AS intercept
    FROM stats
),

/* --- months 25‑36  (Jan‑Dec 2018) -------------------------------------- */
gen(month_step) AS (
    SELECT 25
    UNION ALL
    SELECT month_step+1 FROM gen WHERE month_step < 36
),
forecast_monthly AS (
    SELECT
        r.product_id,
        g.month_step,
        (r.intercept + r.slope * g.month_step)
        * COALESCE(sf.factor,1)                 AS forecast_qty
    FROM   reg r
    JOIN   gen g
    LEFT   JOIN season_factor sf
           ON  sf.product_id = r.product_id
           AND sf.mth_no     = ((g.month_step-1) % 12) + 1
),
annual_forecast AS (
    SELECT  product_id,
            SUM(forecast_qty) AS annual_qty_2018
    FROM    forecast_monthly
    GROUP   BY product_id
)

/* --- final answer ------------------------------------------------------- */
SELECT ROUND(AVG(annual_qty_2018),4) AS avg_forecasted_annual_sales_2018
FROM   annual_forecast;