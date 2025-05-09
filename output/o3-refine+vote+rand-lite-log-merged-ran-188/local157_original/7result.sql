WITH parsed AS (
    SELECT
        ticker,
        market_date,
        /* convert DD-MM-YYYY to YYYY-MM-DD for proper date handling */
        DATE(substr(market_date,7,4) || '-' ||
             substr(market_date,4,2) || '-' ||
             substr(market_date,1,2))        AS market_date_fmt,
        /* turn textual volume into a numeric value                        */
        CASE
            WHEN volume = '-'                       THEN 0
            WHEN volume LIKE '%K'                   THEN CAST(REPLACE(substr(volume,1,length(volume)-1),',','') AS REAL)*1000
            WHEN volume LIKE '%M'                   THEN CAST(REPLACE(substr(volume,1,length(volume)-1),',','') AS REAL)*1000000
            WHEN volume LIKE '%B'                   THEN CAST(REPLACE(substr(volume,1,length(volume)-1),',','') AS REAL)*1000000000
            ELSE CAST(REPLACE(volume,',','') AS REAL)
        END                                         AS volume_num
    FROM bitcoin_prices
    /* restrict to the required date range */
    WHERE DATE(substr(market_date,7,4) || '-' ||
               substr(market_date,4,2) || '-' ||
               substr(market_date,1,2))
          BETWEEN '2021-08-01' AND '2021-08-10'
),
with_prev AS (
    SELECT
        p.*,
        /* previous NON‑ZERO volume for the same ticker                    */
        (
            SELECT p2.volume_num
            FROM parsed p2
            WHERE p2.ticker = p.ticker
              AND p2.market_date_fmt < p.market_date_fmt
              AND p2.volume_num > 0
            ORDER BY p2.market_date_fmt DESC
            LIMIT 1
        ) AS prev_volume_num
    FROM parsed p
)
SELECT
    ticker,
    market_date_fmt       AS market_date,
    ROUND(volume_num,4)   AS volume,
    ROUND(prev_volume_num,4) AS prev_volume,
    CASE
        WHEN prev_volume_num IS NULL
             OR prev_volume_num = 0
        THEN NULL
        ELSE ROUND(
                 (volume_num - prev_volume_num) * 100.0 / prev_volume_num,
                 4
             )
    END                   AS pct_change
FROM with_prev
ORDER BY ticker, market_date_fmt;