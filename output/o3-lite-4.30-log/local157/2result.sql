WITH converted AS (
    SELECT
        "ticker",
        "market_date",
        substr("market_date",7,4) || '-' || substr("market_date",4,2) || '-' || substr("market_date",1,2) AS iso_date,
        CASE
            WHEN "volume" LIKE '%K' THEN CAST(REPLACE("volume",'K','') AS REAL) * 1000
            WHEN "volume" LIKE '%M' THEN CAST(REPLACE("volume",'M','') AS REAL) * 1000000
            WHEN "volume" = '-'     THEN 0
            ELSE CAST("volume" AS REAL)
        END AS vol_num
    FROM "bitcoin_prices"
),
selected AS (
    SELECT *
    FROM converted
    WHERE iso_date BETWEEN '2021-08-01' AND '2021-08-10'
),
non_zero AS (
    SELECT
        ticker,
        iso_date,
        vol_num,
        ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY iso_date) AS rn
    FROM selected
    WHERE vol_num <> 0
),
calc AS (
    SELECT
        s.ticker,
        s."market_date" AS date,
        s.iso_date,
        s.vol_num,
        p.vol_num AS prev_vol
    FROM selected s
    LEFT JOIN non_zero n
           ON n.ticker  = s.ticker
          AND n.iso_date = s.iso_date
    LEFT JOIN non_zero p
           ON p.ticker = n.ticker
          AND p.rn     = n.rn - 1
)
SELECT
    ticker,
    date,
    ROUND(100.0 * (vol_num - prev_vol) / prev_vol, 4) AS volume_pct_change
FROM calc
WHERE prev_vol IS NOT NULL
ORDER BY
    ticker,
    iso_date;