WITH parsed AS (
    /* 1. Keep only the 1‑Aug‑2021 ➜ 10‑Aug‑2021 rows and convert the
          dd‑mm‑yyyy text date into a real DATE plus
          turn the “volume” string into a numeric value                 */
    SELECT
        ticker,
        market_date,
        DATE( substr(market_date,7,4) || '-' ||     -- yyyy
              substr(market_date,4,2) || '-' ||     -- mm
              substr(market_date,1,2) )  AS market_dt,
        CASE
            WHEN volume = '-'                     THEN 0
            WHEN volume LIKE '%K'                 THEN CAST(REPLACE(volume,'K','') AS REAL) * 1000
            WHEN volume LIKE '%M'                 THEN CAST(REPLACE(volume,'M','') AS REAL) * 1000000
            ELSE                                     CAST(volume AS REAL)
        END                                        AS converted_volume
    FROM bitcoin_prices
    WHERE DATE( substr(market_date,7,4) || '-' ||
                substr(market_date,4,2) || '-' ||
                substr(market_date,1,2) )
          BETWEEN '2021-08-01' AND '2021-08-10'
),
prev_non_zero AS (
    /* 2. For every row, locate the most‑recent PRIOR day
          (strictly earlier) whose volume is non‑zero                    */
    SELECT
        p1.*,
        (
          SELECT p2.converted_volume
          FROM parsed p2
          WHERE p2.ticker = p1.ticker
            AND p2.market_dt < p1.market_dt
            AND p2.converted_volume > 0
          ORDER BY p2.market_dt DESC
          LIMIT 1
        ) AS prev_volume
    FROM parsed p1
),
pct_change AS (
    /* 3. Calculate % change versus that previous non‑zero volume        */
    SELECT
        ticker,
        market_date,
        CASE
            WHEN prev_volume IS NULL                  -- first non‑zero row
                 OR prev_volume = 0                   -- safety check
            THEN NULL
            ELSE ROUND( (converted_volume - prev_volume)
                        * 100.0 / prev_volume , 4)
        END AS pct_change_volume
    FROM prev_non_zero
)
SELECT
    ticker,
    market_date,
    pct_change_volume
FROM pct_change
ORDER BY
    ticker,
    DATE( substr(market_date,7,4) || '-' ||
          substr(market_date,4,2) || '-' ||
          substr(market_date,1,2) );