WITH sales AS (           -- 36 months of actual sales (Jan‑2016 … Dec‑2018)
    SELECT  product_id,
            mth,
            ((CAST(strftime('%Y',mth) AS INTEGER)-2016)*12) + CAST(strftime('%m',mth) AS INTEGER)   AS idx,   -- 1‑based month index
            CAST(strftime('%m',mth) AS INTEGER)                                                   AS mo,    -- month of year
            qty*1.0                                                                               AS qty
    FROM    monthly_sales
    WHERE   product_id IN (4160,7790)
      AND   mth BETWEEN '2016-01-01' AND '2018-12-31'
),
reg_input AS (            -- period to build seasonality & regression (idx 7 … 30)
    SELECT * FROM sales WHERE idx BETWEEN 7 AND 30
),

/* --------  seasonality factors (built on idx 7‑30)  -------- */
prod_avg AS (
    SELECT product_id, AVG(qty) AS avg_total
    FROM   reg_input
    GROUP  BY product_id
),
prod_mo_avg AS (
    SELECT product_id, mo, AVG(qty) AS avg_mo
    FROM   reg_input
    GROUP  BY product_id, mo
),
season AS (
    SELECT m.product_id,
           m.mo,
           m.avg_mo * 1.0 / a.avg_total  AS season_idx          -- >1 high season, <1 low season
    FROM   prod_mo_avg m
    JOIN   prod_avg     a USING (product_id)
),

/* --------  deseasonalise and build weighted‑(ordinary) regression  -------- */
reg_data AS (
    SELECT r.product_id,
           r.idx,
           r.qty / s.season_idx           AS qty_adj            -- remove seasonality
    FROM   reg_input r
    JOIN   season   s  ON s.product_id = r.product_id
                      AND s.mo        = r.mo
),
stats AS (                -- pre‑compute sums for closed‑form OLS
    SELECT product_id,
           COUNT(*)            AS n,
           SUM(idx)            AS sx,
           SUM(idx*idx)        AS sx2,
           SUM(qty_adj)        AS sy,
           SUM(idx*qty_adj)    AS sxy
    FROM   reg_data
    GROUP  BY product_id
),
coeff AS (                -- slope (b) and intercept (a)
    SELECT product_id,
           (n*sxy - sx*sy) * 1.0 / (n*sx2 - sx*sx)                       AS b,
           (sy - ((n*sxy - sx*sy) * 1.0 / (n*sx2 - sx*sx))*sx) / n       AS a
    FROM   stats
),

/* --------  forecast each month of 2018 (idx 25 … 36)  -------- */
forecast_months AS (
    SELECT p.product_id,
           i.idx,
           ((i.idx-1) % 12) + 1                    AS mo            -- month‑of‑year for season factor
    FROM  (SELECT 25 AS idx UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL
           SELECT 29 UNION ALL SELECT 30 UNION ALL SELECT 31 UNION ALL SELECT 32 UNION ALL
           SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35 UNION ALL SELECT 36) i
    CROSS JOIN (SELECT DISTINCT product_id FROM coeff) p
),
forecast_calc AS (
    SELECT f.product_id,
           (c.a + c.b * f.idx) * s.season_idx      AS forecast_qty   -- re‑apply seasonality
    FROM   forecast_months f
    JOIN   coeff   c  USING (product_id)
    JOIN   season  s  ON s.product_id = f.product_id
                     AND s.mo        = f.mo
),
annual_forecast AS (
    SELECT product_id, SUM(forecast_qty) AS annual_qty
    FROM   forecast_calc
    GROUP  BY product_id
)

/* --------  requested result  -------- */
SELECT ROUND(AVG(annual_qty),4) AS avg_forecast_annual_sales_2018
FROM   annual_forecast;