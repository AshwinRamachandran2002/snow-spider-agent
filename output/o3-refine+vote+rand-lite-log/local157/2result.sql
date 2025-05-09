WITH cleaned AS (   /* 1. keep 1‑10 Aug 2021 and turn the “volume” text into a real number */
    SELECT
        ticker,
        market_date,                                        -- original dd‑mm‑yyyy text
        date( substr(market_date,7,4) || '-'                -- yyyy
              || substr(market_date,4,2) || '-'             -- mm
              || substr(market_date,1,2) )  AS market_dt,   -- yyyy‑mm‑dd (ISO) for easy ordering
        CASE                                             -- convert K / M / B and “-”
            WHEN volume = '-'                  THEN 0
            WHEN upper(volume) LIKE '%K'       THEN 1.0 * REPLACE(upper(volume),'K','') * 1000
            WHEN upper(volume) LIKE '%M'       THEN 1.0 * REPLACE(upper(volume),'M','') * 1000000
            WHEN upper(volume) LIKE '%B'       THEN 1.0 * REPLACE(upper(volume),'B','') * 1000000000
            ELSE CAST(volume AS REAL)
        END AS vol_num
    FROM bitcoin_prices
    WHERE date( substr(market_date,7,4)||'-'||substr(market_date,4,2)||'-'||substr(market_date,1,2) )
          BETWEEN '2021-08-01' AND '2021-08-10'
),
-- 2. find the most‑recent *non‑zero* volume for each ticker before the current day
calc AS (
    SELECT
        c1.ticker,
        c1.market_dt,
        c1.vol_num,
        (
            SELECT c2.vol_num
            FROM cleaned c2
            WHERE c2.ticker = c1.ticker
              AND c2.market_dt < c1.market_dt
              AND c2.vol_num <> 0
            ORDER BY c2.market_dt DESC
            LIMIT 1
        ) AS prev_vol
    FROM cleaned c1
)
SELECT
    ticker,
    strftime('%d-%m-%Y', market_dt)                AS market_date,
    vol_num                                        AS volume,
    prev_vol                                       AS previous_volume,
    CASE
        WHEN prev_vol IS NOT NULL AND prev_vol <> 0
        THEN ROUND( (vol_num - prev_vol) * 100.0 / prev_vol , 4)
        ELSE NULL
    END                                            AS pct_change_volume
FROM calc
ORDER BY ticker, market_dt;