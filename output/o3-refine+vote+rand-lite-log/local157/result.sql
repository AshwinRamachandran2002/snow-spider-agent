WITH parsed AS (
    /* convert the volume text into a numeric value */
    SELECT
        ticker,
        market_date,
        date(substr(market_date,7,4)||'-'||substr(market_date,4,2)||'-'||substr(market_date,1,2))      AS market_date_iso,
        CASE
            WHEN volume = '-'                     THEN 0
            WHEN volume LIKE '%K'                 THEN CAST(REPLACE(SUBSTR(volume,1,LENGTH(volume)-1),',','') AS REAL) * 1000
            WHEN volume LIKE '%M'                 THEN CAST(REPLACE(SUBSTR(volume,1,LENGTH(volume)-1),',','') AS REAL) * 1000000
            ELSE CAST(REPLACE(volume,',','') AS REAL)
        END                                                                               AS volume_numeric
    FROM bitcoin_prices
),
filtered AS (
    /* keep only the dates from 2021‑08‑01 to 2021‑08‑10 (inclusive) */
    SELECT *
    FROM parsed
    WHERE market_date_iso BETWEEN '2021-08-01' AND '2021-08-10'
),
prev_non_zero AS (
    /* find the most‑recent earlier non‑zero volume for each row */
    SELECT
        f1.ticker,
        f1.market_date,
        f1.market_date_iso,
        f1.volume_numeric,
        (
            SELECT f2.volume_numeric
            FROM filtered AS f2
            WHERE f2.ticker = f1.ticker
              AND f2.market_date_iso < f1.market_date_iso
              AND f2.volume_numeric > 0
            ORDER BY f2.market_date_iso DESC
            LIMIT 1
        ) AS prev_volume
    FROM filtered AS f1
)
SELECT
    ticker,
    market_date,
    CASE
        WHEN prev_volume IS NULL
             THEN NULL
        ELSE ROUND( (volume_numeric - prev_volume) * 100.0 / prev_volume , 4)
    END AS pct_change_volume
FROM prev_non_zero
ORDER BY
    ticker,
    market_date_iso;