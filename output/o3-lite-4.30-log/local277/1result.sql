WITH ranked AS (
    /* assign a running index (t_idx) starting with 1 for 2016‑01‑01          */
    SELECT  m."product_id",
            m."mth",
            m."qty",
            (SELECT COUNT(*)
             FROM   "monthly_sales" m2
             WHERE  m2."product_id" = m."product_id"
               AND  m2."mth"        <= m."mth")          AS t_idx,
            CAST(STRFTIME('%m', m."mth") AS INTEGER)     AS month_no
    FROM   "monthly_sales" m
    WHERE  m."product_id" IN (4160, 7790)
),
first36 AS (
    /* keep the first 36 months (Jan‑2016 … Dec‑2018)                       */
    SELECT *
    FROM   ranked
    WHERE  t_idx <= 36
),
w_stats AS (
    /* weighted‑least‑squares components using weight w = t_idx             */
    SELECT  "product_id",
            SUM(t_idx)                                    AS sum_w,         -- Σ w
            SUM(t_idx * t_idx)                            AS sum_wx,        -- Σ w * x
            SUM(t_idx * "qty")                            AS sum_wy,        -- Σ w * y
            SUM(t_idx * t_idx * t_idx)                    AS sum_wxx,       -- Σ w * x²
            SUM(t_idx * t_idx * "qty")                    AS sum_wxy        -- Σ w * x * y
    FROM    first36
    GROUP BY "product_id"
),
coeff AS (
    /* slope & intercept for each product (weighted regression)             */
    SELECT  s."product_id",
            ( (s.sum_w * 1.0 * s.sum_wxy) - (s.sum_wx * 1.0 * s.sum_wy) )
            /
            ( (s.sum_w * 1.0 * s.sum_wxx) - (s.sum_wx * 1.0 * s.sum_wx) )
            AS slope,
            ( (s.sum_wxx * 1.0 * s.sum_wy) - (s.sum_wx * 1.0 * s.sum_wxy) )
            /
            ( (s.sum_w * 1.0 * s.sum_wxx) - (s.sum_wx * 1.0 * s.sum_wx) )
            AS intercept
    FROM    w_stats s
),
trend AS (
    /* add trend value to every of the first 36 observations                */
    SELECT  f.*,
            c.slope,
            c.intercept,
            (c.slope * f.t_idx + c.intercept)            AS trend_val
    FROM    first36 f
    JOIN    coeff   c USING ("product_id")
),
season_idx AS (
    /* seasonal indices based on time‑steps 7 → 30                          */
    SELECT  "product_id",
            month_no,
            AVG("qty" * 1.0 / trend_val)                 AS seasonal_idx
    FROM    trend
    WHERE   t_idx BETWEEN 7 AND 30
    GROUP BY "product_id", month_no
),
forecast_2018 AS (
    /* forecast months belonging to 2018 (t_idx 25‑36)                      */
    SELECT  t."product_id",
            t."mth",
            t_idx,
            t.trend_val,
            s.seasonal_idx,
            t.trend_val * s.seasonal_idx                 AS forecast_qty
    FROM    trend t
    JOIN    season_idx s
          ON s."product_id" = t."product_id"
         AND s.month_no     = t.month_no
    WHERE   t_idx BETWEEN 25 AND 36                      -- 2018 months
),
annual AS (
    SELECT  "product_id",
            SUM(forecast_qty)                            AS forecasted_annual_sales_2018
    FROM    forecast_2018
    GROUP BY "product_id"
)
SELECT  "product_id",
        ROUND(forecasted_annual_sales_2018, 4) AS forecasted_annual_sales_2018
FROM    annual
ORDER BY "product_id";