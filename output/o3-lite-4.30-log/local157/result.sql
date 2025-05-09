WITH cleaned AS (
    SELECT
        "ticker",
        DATE(SUBSTR("market_date",7,4) || '-' ||
             SUBSTR("market_date",4,2) || '-' ||
             SUBSTR("market_date",1,2))                    AS dt,
        "market_date",
        CASE
            WHEN "volume" = '-'      THEN 0
            WHEN "volume" LIKE '%K'  THEN CAST(REPLACE("volume",'K','') AS REAL) * 1000
            WHEN "volume" LIKE '%M'  THEN CAST(REPLACE("volume",'M','') AS REAL) * 1000000
            ELSE CAST("volume" AS REAL)
        END                                               AS vol_num
    FROM "bitcoin_prices"
),
lagged AS (
    SELECT
        *,
        MAX(CASE WHEN vol_num > 0 THEN dt END)
            OVER (PARTITION BY ticker
                  ORDER BY dt
                  ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prev_dt
    FROM cleaned
),
paired AS (
    SELECT
        cur.ticker,
        cur.market_date AS date,
        cur.dt,
        cur.vol_num             AS today_vol,
        prev.vol_num            AS prev_vol
    FROM  lagged  AS cur
    LEFT  JOIN cleaned AS prev
           ON prev.ticker = cur.ticker
          AND prev.dt     = cur.prev_dt
)
SELECT
    ticker,
    date,
    CASE
        WHEN prev_vol IS NULL OR prev_vol = 0
             THEN NULL
        ELSE ROUND((today_vol - prev_vol) * 100.0 / prev_vol, 4)
    END AS volume_pct_change
FROM paired
WHERE dt BETWEEN '2021-08-01' AND '2021-08-10'
ORDER BY ticker, dt;