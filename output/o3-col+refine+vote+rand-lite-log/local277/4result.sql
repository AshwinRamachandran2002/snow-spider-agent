WITH seq AS (                  -- 36 months: Jan-2016 … Dec-2018
    SELECT product_id,
           ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY mth) AS idx,
           qty,
           CASE WHEN ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY mth)
                    BETWEEN 7 AND 30 THEN 2.0 ELSE 1.0 END         AS w
    FROM   monthly_sales
    WHERE  product_id IN (4160, 7790)
      AND  mth >= '2016-01-01'
      AND  mth <  '2019-01-01'
),
sums AS (                      -- weighted sums for regression
    SELECT product_id,
           SUM(w)                      AS sw,
           SUM(w*idx)                  AS swx,
           SUM(w*idx*idx)              AS swx2,
           SUM(w*qty)                  AS swy,
           SUM(w*idx*qty)              AS swxy
    FROM   seq
    GROUP  BY product_id
),
coeff AS (                     -- slope & intercept
    SELECT product_id,
           (swxy - swx*swy/sw) / (swx2 - swx*swx/sw)     AS slope,
           (swy  - ((swxy - swx*swy/sw) /
                    (swx2 - swx*swx/sw))*swx) / sw       AS intercept
    FROM   sums
),
forecast AS (                  -- predict months 25-36  (Jan-2018 … Dec-2018)
    SELECT s.product_id,
           idx,
           intercept + slope*idx            AS forecast_qty
    FROM   seq  s
    JOIN   coeff c USING (product_id)
    WHERE  idx BETWEEN 25 AND 36
),
annual AS (                    -- annual forecast per product
    SELECT product_id,
           SUM(forecast_qty)   AS annual_forecast_2018
    FROM   forecast
    GROUP  BY product_id
)
SELECT ROUND(AVG(annual_forecast_2018),4) AS avg_forecast_annual_sales_2018
FROM   annual;