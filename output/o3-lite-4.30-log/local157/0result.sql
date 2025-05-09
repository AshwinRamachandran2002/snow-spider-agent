WITH normalised AS (
    SELECT  ticker,
            market_date,
            CASE
                WHEN volume = '-'      THEN 0
                WHEN volume LIKE '%K'  THEN CAST(REPLACE(volume,'K','') AS REAL) * 1000
                WHEN volume LIKE '%M'  THEN CAST(REPLACE(volume,'M','') AS REAL) * 1000000
                ELSE CAST(volume AS REAL)
            END AS numeric_volume
    FROM   bitcoin_prices
),
aug_window AS (
    SELECT *
    FROM   normalised
    WHERE  DATE(substr(market_date,7,4)||'-'||substr(market_date,4,2)||'-'||substr(market_date,1,2))
           BETWEEN '2021-08-01' AND '2021-08-10'
),
non_zero AS (
    SELECT *
    FROM   normalised
    WHERE  numeric_volume <> 0
),
prev_lookup AS (
    SELECT  a.ticker,
            a.market_date,
            a.numeric_volume,
            (
                SELECT  b.numeric_volume
                FROM    non_zero b
                WHERE   b.ticker = a.ticker
                  AND   DATE(substr(b.market_date,7,4)||'-'||substr(b.market_date,4,2)||'-'||substr(b.market_date,1,2))
                        < DATE(substr(a.market_date,7,4)||'-'||substr(a.market_date,4,2)||'-'||substr(a.market_date,1,2))
                ORDER BY DATE(substr(b.market_date,7,4)||'-'||substr(b.market_date,4,2)||'-'||substr(b.market_date,1,2)) DESC
                LIMIT 1
            ) AS prev_nonzero_volume
    FROM   aug_window a
)
SELECT  ticker,
        market_date AS date,
        CASE
            WHEN prev_nonzero_volume IS NULL THEN NULL
            ELSE ROUND(
                     100.0 * (numeric_volume - prev_nonzero_volume) / prev_nonzero_volume,
                     4
                 )
        END AS volume_pct_change
FROM    prev_lookup
ORDER BY ticker,
         DATE(substr(market_date,7,4)||'-'||substr(market_date,4,2)||'-'||substr(market_date,1,2));