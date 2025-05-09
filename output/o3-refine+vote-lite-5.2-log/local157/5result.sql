WITH vol AS (
    /* Convert the raw text volume into a pure numeric value
       and put the date into YYYY‑MM‑DD format               */
    SELECT
        ticker,
        DATE(SUBSTR(market_date, 7, 4) || '-' ||
             SUBSTR(market_date, 4, 2) || '-' ||
             SUBSTR(market_date, 1, 2))      AS market_date_fmt,
        CASE
            WHEN volume = '-'                THEN 0
            WHEN volume LIKE '%K'            THEN
                 CAST(REPLACE(SUBSTR(volume, 1, LENGTH(volume) - 1), ',', '') AS REAL) * 1000
            WHEN volume LIKE '%M'            THEN
                 CAST(REPLACE(SUBSTR(volume, 1, LENGTH(volume) - 1), ',', '') AS REAL) * 1000000
            ELSE
                 CAST(REPLACE(volume, ',', '') AS REAL)
        END                                   AS volume_value
    FROM bitcoin_prices
),
/* restrict to the required ten‑day window and, for every row,
   find the latest earlier NON‑ZERO volume for the same ticker */
windowed AS (
    SELECT
        v.*,
        (
          SELECT v2.volume_value
          FROM   vol v2
          WHERE  v2.ticker = v.ticker
            AND  v2.volume_value <> 0
            AND  v2.market_date_fmt < v.market_date_fmt
          ORDER BY v2.market_date_fmt DESC
          LIMIT 1
        )                                        AS prev_volume
    FROM vol v
    WHERE v.market_date_fmt BETWEEN '2021-08-01' AND '2021-08-10'
)
SELECT
    ticker,
    market_date_fmt          AS market_date,
    volume_value,
    ROUND(
        CASE
            WHEN prev_volume IS NOT NULL AND prev_volume <> 0
            THEN (volume_value - prev_volume) * 100.0 / prev_volume
        END, 4
    )                       AS pct_change_volume
FROM windowed
ORDER BY ticker, market_date;