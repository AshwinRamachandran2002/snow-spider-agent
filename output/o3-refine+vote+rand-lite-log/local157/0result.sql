WITH cleaned AS (   -- standardise date format and convert volume to a number
    SELECT
        ticker,
        market_date,
        DATE( SUBSTR(market_date,7,4) || '-' || SUBSTR(market_date,4,2) || '-' || SUBSTR(market_date,1,2) ) AS iso_date,
        CASE
            WHEN volume = '-'                            THEN 0
            WHEN volume LIKE '%K'                        THEN CAST(REPLACE(volume,'K','') AS REAL) * 1000
            WHEN volume LIKE '%M'                        THEN CAST(REPLACE(volume,'M','') AS REAL) * 1000000
            WHEN volume LIKE '%B'                        THEN CAST(REPLACE(volume,'B','') AS REAL) * 1000000000
            ELSE CAST(volume AS REAL)
        END                                             AS volume_num
    FROM bitcoin_prices
    -- include a few weeks before August so a “previous‐day” volume is available
    WHERE DATE( SUBSTR(market_date,7,4) || '-' || SUBSTR(market_date,4,2) || '-' || SUBSTR(market_date,1,2) )
          BETWEEN '2021-07-01' AND '2021-08-10'
),
august AS (          -- keep only the days we have to report on
    SELECT *
    FROM cleaned
    WHERE iso_date BETWEEN '2021-08-01' AND '2021-08-10'
),
with_prev AS (       -- find the most‑recent earlier non‑zero volume for each record
    SELECT
        a.ticker,
        a.market_date,
        a.iso_date,
        a.volume_num,
        (
            SELECT p.volume_num
            FROM cleaned p
            WHERE p.ticker = a.ticker
              AND p.iso_date < a.iso_date
              AND p.volume_num > 0
            ORDER BY p.iso_date DESC
            LIMIT 1
        ) AS prev_volume
    FROM august a
)
SELECT
    ticker,
    market_date,
    CASE
        WHEN prev_volume IS NULL               THEN NULL          -- no prior non‑zero volume
        ELSE ROUND( (volume_num - prev_volume) * 100.0 / prev_volume , 4)
    END AS pct_change_volume
FROM with_prev
ORDER BY ticker, iso_date;