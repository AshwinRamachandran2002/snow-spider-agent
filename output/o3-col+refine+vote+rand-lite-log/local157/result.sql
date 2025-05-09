WITH vol AS (   -- convert raw volume strings to numbers and keep 1-10 Aug 2021 rows
    SELECT
        "ticker",
        "market_date",
        CASE
             WHEN "volume" = '-'            THEN 0
             WHEN "volume" LIKE '%K'        THEN CAST(REPLACE("volume",'K','') AS REAL) * 1000
             WHEN "volume" LIKE '%M'        THEN CAST(REPLACE("volume",'M','') AS REAL) * 1000000
             ELSE CAST("volume" AS REAL)
        END AS volume_num
    FROM   "bitcoin_prices"
    WHERE  "market_date" BETWEEN '01-08-2021' AND '10-08-2021'
),
prev_vol AS (   -- find the most-recent non-zero volume for each row
    SELECT
        v1.ticker,
        v1.market_date,
        v1.volume_num,
        (
            SELECT v2.volume_num
            FROM   vol v2
            WHERE  v2.ticker       = v1.ticker
              AND  v2.market_date < v1.market_date
              AND  v2.volume_num  > 0                -- only non-zero volumes
            ORDER  BY v2.market_date DESC
            LIMIT 1
        ) AS prev_volume_num
    FROM   vol v1
)
SELECT
    ticker,
    market_date,
    volume_num,
    prev_volume_num,
    CASE
        WHEN prev_volume_num IS NULL OR prev_volume_num = 0
             THEN NULL
        ELSE ROUND( (volume_num - prev_volume_num) * 100.0 / prev_volume_num , 4)
    END AS pct_change
FROM   prev_vol
ORDER  BY ticker,
          market_date;