WITH converted AS (
    /* 1.  Keep only 1-10 Aug-2021 and turn the text “volume” into a pure number  */
    SELECT  "ticker",
            "market_date",
            CASE
                WHEN "volume" = '-'          THEN 0                         -- missing data
                WHEN "volume" LIKE '%K'      THEN CAST(REPLACE("volume",'K','') AS REAL) * 1000
                WHEN "volume" LIKE '%M'      THEN CAST(REPLACE("volume",'M','') AS REAL) * 1000000
                ELSE CAST("volume" AS REAL)
            END AS vol_num
    FROM    "bitcoin_prices"
    WHERE   "market_date" BETWEEN '01-08-2021' AND '10-08-2021'
),
with_prev AS (
    /* 2.  For every row find the most-recent earlier *non-zero* volume for that ticker */
    SELECT  c1."ticker",
            c1."market_date",
            c1.vol_num,
            (
                SELECT  c2.vol_num
                FROM    converted AS c2
                WHERE   c2."ticker" = c1."ticker"
                  AND   date(substr(c2."market_date",7,4)||'-'||substr(c2."market_date",4,2)||'-'||substr(c2."market_date",1,2))
                         < date(substr(c1."market_date",7,4)||'-'||substr(c1."market_date",4,2)||'-'||substr(c1."market_date",1,2))
                  AND   c2.vol_num > 0
                ORDER BY date(substr(c2."market_date",7,4)||'-'||substr(c2."market_date",4,2)||'-'||substr(c2."market_date",1,2)) DESC
                LIMIT 1
            ) AS prev_nonzero_vol
    FROM    converted AS c1
)
SELECT  "ticker",
        "market_date",
        ROUND(100.0 * (vol_num - prev_nonzero_vol) / prev_nonzero_vol, 4) AS pct_change_volume
FROM    with_prev
WHERE   prev_nonzero_vol IS NOT NULL          -- need a previous non-zero volume for the comparison
ORDER BY "ticker",
         date(substr("market_date",7,4)||'-'||substr("market_date",4,2)||'-'||substr("market_date",1,2));