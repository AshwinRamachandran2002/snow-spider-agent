WITH RECURSIVE
prod_months AS (           -- 36 months of history per product
        SELECT  product_id,
                mth,
                qty,
                ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY mth) AS t
        FROM    monthly_sales
        WHERE   product_id IN (4160,7790)
          AND   mth BETWEEN '2016-01-01' AND '2018-12-01'
),
reg_stats AS (                  -- basic sums for regression
        SELECT  product_id,
                COUNT(*)                    AS n,
                SUM(t)                      AS sx,
                SUM(qty)                    AS sy,
                SUM(t*t)                    AS sx2,
                SUM(t*qty)                  AS sxy
        FROM    prod_months
        GROUP BY product_id
),
reg_params AS (                 -- slope & intercept
        SELECT  product_id,
                (n*sxy - sx*sy)*1.0 /(n*sx2 - sx*sx)                  AS slope,
                (sy - ((n*sxy - sx*sy)*1.0 /(n*sx2 - sx*sx))*sx)*1.0/n AS intercept
        FROM    reg_stats
),
seasonality_base AS (           -- July‑2016 (t=7) … Jun‑2018 (t=30)
        SELECT  p.product_id,
                strftime('%m',p.mth)                      AS mon,
                p.qty /(r.intercept + r.slope*p.t)        AS ratio
        FROM    prod_months p
        JOIN    reg_params r USING (product_id)
        WHERE   p.t BETWEEN 7 AND 30
),
seasonality_factor AS (         -- average seasonal factor per month
        SELECT  product_id,
                mon,
                AVG(ratio) AS factor
        FROM    seasonality_base
        GROUP BY product_id, mon
),
nums(t) AS (                    -- helper rows 25 … 36  (months of 2018)
        SELECT 25
        UNION ALL
        SELECT t+1 FROM nums WHERE t < 36
),
forecast_raw AS (               -- trend forecast before seasonality
        SELECT  p.product_id,
                n.t,
                date('2016-01-01',printf('+%d months',n.t-1)) AS mth,
                r.intercept + r.slope*n.t                     AS trend_qty
        FROM        (SELECT DISTINCT product_id FROM prod_months) p
        CROSS JOIN   nums n
        JOIN         reg_params r  USING (product_id)
),
forecast_adj AS (               -- apply seasonal factors
        SELECT  f.product_id,
                f.mth,
                f.trend_qty * COALESCE(s.factor,1.0) AS forecast_qty
        FROM    forecast_raw f
        LEFT JOIN seasonality_factor s
               ON s.product_id = f.product_id
              AND s.mon        = strftime('%m',f.mth)
),
annual_2018 AS (                -- yearly total per product
        SELECT  product_id,
                SUM(forecast_qty) AS annual_qty
        FROM    forecast_adj
        WHERE   mth BETWEEN '2018-01-01' AND '2018-12-31'
        GROUP BY product_id
)
SELECT  AVG(annual_qty) AS avg_forecast_annual_sales_2018
FROM    annual_2018;