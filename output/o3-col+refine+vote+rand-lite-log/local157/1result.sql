WITH normalised_volume AS (
    /* 1. Convert the raw volume strings to pure numbers and
          cast market_date into ISO-8601 so it sorts correctly   */
    SELECT
        "ticker",
        DATE(SUBSTR("market_date",7,4)||'-'||SUBSTR("market_date",4,2)||'-'||SUBSTR("market_date",1,2)) AS iso_date,
        CASE
            WHEN "volume" = '-'              THEN 0
            WHEN "volume" LIKE '%K'          THEN CAST(REPLACE("volume",'K','') AS REAL) * 1000
            WHEN "volume" LIKE '%M'          THEN CAST(REPLACE("volume",'M','') AS REAL) * 1000000
            ELSE CAST("volume" AS REAL)
        END                                                   AS volume_num
    FROM   "bitcoin_prices"
    WHERE  DATE(SUBSTR("market_date",7,4)||'-'||SUBSTR("market_date",4,2)||'-'||SUBSTR("market_date",1,2))
           BETWEEN '2021-08-01' AND '2021-08-10'
),
prev_non_zero AS (
    /* 2. For each row, find the most recent non-zero volume
          for the same ticker on any prior day                */
    SELECT
        n1.ticker,
        n1.iso_date,
        n1.volume_num                                         AS volume_now,
        (
            SELECT  n2.volume_num
            FROM    normalised_volume n2
            WHERE   n2.ticker   = n1.ticker
              AND   n2.iso_date < n1.iso_date
              AND   n2.volume_num <> 0
            ORDER BY n2.iso_date DESC
            LIMIT 1
        )                                                     AS volume_prev
    FROM   normalised_volume n1
)
SELECT
    ticker,
    iso_date,
    ROUND(
          100.0 * (volume_now - volume_prev) / volume_prev
    , 2)                                                      AS pct_change_volume
FROM   prev_non_zero
WHERE  volume_prev > 0                      -- avoid divide-by-zero
ORDER  BY ticker,
          iso_date;