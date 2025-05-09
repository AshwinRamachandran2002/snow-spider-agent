WITH converted AS (
    /* 1️⃣  Convert the raw “volume” text to a pure number
           and re-format the date so it can be sorted chronologically */
    SELECT  "ticker",
            "market_date",
            CASE
                WHEN "volume" = '-'          THEN 0
                WHEN "volume" LIKE '%K'      THEN CAST(REPLACE("volume",'K','') AS REAL) * 1000
                WHEN "volume" LIKE '%M'      THEN CAST(REPLACE("volume",'M','') AS REAL) * 1000000
                ELSE CAST("volume" AS REAL)
            END                                           AS volume_num,
            SUBSTR("market_date",7,4) || '-' ||
            SUBSTR("market_date",4,2) || '-' ||
            SUBSTR("market_date",1,2)                    AS iso_date
    FROM    "bitcoin_prices"
),
base AS (
    /* 2️⃣  Attach the most-recent *non-zero* volume that
           occurred **before** the current row’s date       */
    SELECT  c1.ticker,
            c1.market_date,
            c1.volume_num,
            ( SELECT  c2.volume_num
              FROM    converted c2
              WHERE   c2.ticker      = c1.ticker
              AND     c2.volume_num <> 0                -- only non-zero
              AND     c2.iso_date   < c1.iso_date       -- strictly before
              ORDER BY c2.iso_date DESC
              LIMIT   1 )                               AS prev_non_zero
    FROM    converted c1
    WHERE   c1.iso_date BETWEEN '2021-08-01' AND '2021-08-10'
)
SELECT  ticker,
        market_date,
        volume_num                                    AS volume_numeric,
        CASE
            WHEN prev_non_zero IS NULL OR prev_non_zero = 0
                 THEN NULL
            ELSE ROUND( (volume_num - prev_non_zero)
                         * 100.0 / prev_non_zero , 4 )
        END                                           AS pct_change_vs_prev_non_zero
FROM    base
ORDER BY ticker,
         SUBSTR(market_date,7,4) || SUBSTR(market_date,4,2) || SUBSTR(market_date,1,2);