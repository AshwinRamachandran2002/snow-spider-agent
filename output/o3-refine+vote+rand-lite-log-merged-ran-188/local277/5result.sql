WITH ms AS (                         -- 36 months: 2016-01-01 … 2018-12-01
    SELECT
        "product_id",
        "mth",
        "qty",
        ROW_NUMBER() OVER (PARTITION BY "product_id" ORDER BY "mth") AS t
    FROM "monthly_sales"
    WHERE "product_id" IN (4160, 7790)
      AND "mth" BETWEEN '2016-01-01' AND '2018-12-01'
),
train AS (                           -- seasonality window: steps 7 … 30
    SELECT
        "product_id",
        t      AS x,
        "qty"  AS y,
        t      AS w                   -- weight = time-step (more recent → larger)
    FROM ms
    WHERE t BETWEEN 7 AND 30
),
agg AS (                             -- helper sums for weighted regression
    SELECT
        "product_id",
        SUM(w)         AS Sw,
        SUM(w*x)       AS Swx,
        SUM(w*y)       AS Swy,
        SUM(w*x*x)     AS Swx2,
        SUM(w*x*y)     AS Swxy
    FROM train
    GROUP BY "product_id"
),
params AS (                          -- slope & intercept
    SELECT
        "product_id",
        (Sw * Swxy - Swx * Swy) * 1.0 / (Sw * Swx2 - Swx * Swx)               AS slope,
        (Swy - ((Sw * Swxy - Swx * Swy) * 1.0 / (Sw * Swx2 - Swx * Swx)) 
               * Swx) * 1.0 / Sw                                              AS intercept
    FROM agg
),
ofs AS (                             -- offsets 0 … 11  (months Jan-Dec 2018)
    SELECT 0 AS ofs UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
    UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
),
forecast AS (                        -- predict months 25 … 36 (year 2018)
    SELECT
        p."product_id",
        25 + ofs.ofs                        AS x,
        p.intercept + p.slope * (25 + ofs.ofs) AS y_hat
    FROM params p
    CROSS JOIN ofs
)
SELECT
    "product_id",
    ROUND(AVG(y_hat), 4) AS avg_forecast_2018
FROM forecast
GROUP BY "product_id";