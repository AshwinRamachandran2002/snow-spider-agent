WITH sales AS (
    SELECT
        product_id,
        mth,
        qty,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY mth
        )                    AS t                 -- 1 … 36
    FROM monthly_sales
    WHERE product_id IN (4160,7790)
      AND mth >= '2016-01-01'
      AND mth <  '2019-01-01'                    -- first 36 months
),
stats AS (                                         -- basic sums
    SELECT
        product_id,
        COUNT(*)                    AS n,         -- = 36
        SUM(t)                      AS sum_t,
        SUM(qty)                    AS sum_y,
        SUM(t*t)                    AS sum_tt,
        SUM(t*qty)                  AS sum_ty
    FROM sales
    GROUP BY product_id
),
slope_calc AS (                                    -- weighted‑(ordinary) regression slope
    SELECT
        product_id,
        (n*sum_ty - sum_t*sum_y)*1.0 /
        NULLIF(n*sum_tt - sum_t*sum_t,0)  AS slope
    FROM stats
),
params AS (                                        -- regression parameters
    SELECT
        st.product_id,
        sc.slope,
        (st.sum_y - sc.slope*st.sum_t)*1.0 / st.n AS intercept
    FROM stats st
    JOIN slope_calc sc USING (product_id)
),
trend AS (                                         -- fitted trend for every time‑step
    SELECT
        s.*,
        p.intercept + p.slope*s.t     AS trend,
        STRFTIME('%m',s.mth)          AS month_no
    FROM sales s
    JOIN params p USING (product_id)
),
seasonality AS (                                   -- seasonal indices from steps 7‑30
    SELECT
        product_id,
        month_no,
        AVG( qty / NULLIF(trend,0) )  AS season_factor
    FROM trend
    WHERE t BETWEEN 7 AND 30
    GROUP BY product_id, month_no
),
forecast_2018 AS (                                 -- forecast each month in 2018
    SELECT
        tr.product_id,
        tr.mth,
        tr.trend,
        COALESCE(se.season_factor,1.0)           AS season_factor,
        tr.trend * COALESCE(se.season_factor,1.0) AS forecast_qty
    FROM trend tr
    LEFT JOIN seasonality se
           ON se.product_id = tr.product_id
          AND se.month_no  = tr.month_no
    WHERE tr.mth >= '2018-01-01'
      AND tr.mth <  '2019-01-01'
),
annual_product AS (                                -- annual forecast per product
    SELECT
        product_id,
        SUM(forecast_qty)  AS annual_forecast_2018
    FROM forecast_2018
    GROUP BY product_id
)
SELECT
    AVG(annual_forecast_2018) AS avg_forecast_annual_sales_2018
FROM annual_product;