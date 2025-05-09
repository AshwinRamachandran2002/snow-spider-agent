WITH cleaned AS (
    -- 1. standardise the date and convert the volume field to a pure number
    SELECT
        "ticker",
        "market_date",
        DATE(substr("market_date",7,4) || '-' || substr("market_date",4,2) || '-' || substr("market_date",1,2)) AS dt,
        CASE
            WHEN "volume" IS NULL OR "volume" = '-'              THEN 0
            WHEN "volume" LIKE '%K'                              THEN CAST(REPLACE("volume",'K','') AS REAL) * 1000
            WHEN "volume" LIKE '%M'                              THEN CAST(REPLACE("volume",'M','') AS REAL) * 1000000
            ELSE CAST("volume" AS REAL)
        END                                                     AS vol_num
    FROM "bitcoin_prices"
), period_data AS (
    -- 2. keep only the dates of interest
    SELECT *
    FROM cleaned
    WHERE dt BETWEEN '2021-08-01' AND '2021-08-10'
), with_prev AS (
    -- 3. locate the most‑recent NON‑ZERO volume before each day (within the period)
    SELECT
        p1.*,
        (
            SELECT p2.vol_num
            FROM period_data p2
            WHERE p2.ticker = p1.ticker
              AND p2.vol_num > 0
              AND p2.dt       < p1.dt
            ORDER BY p2.dt DESC
            LIMIT 1
        ) AS prev_vol
    FROM period_data p1
)
-- 4. calculate % change and show the result
SELECT
    ticker,
    market_date,
    vol_num            AS current_volume,
    prev_vol           AS previous_volume,
    CASE
        WHEN prev_vol IS NULL OR prev_vol = 0 THEN NULL
        ELSE ROUND( (vol_num - prev_vol) * 100.0 / prev_vol , 4)
    END                AS pct_change
FROM with_prev
ORDER BY
    ticker,
    dt;