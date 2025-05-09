WITH volumes AS (
    SELECT
        "ticker",
        "market_date",
        CASE
            WHEN "volume" = '-'         THEN 0.0
            WHEN "volume" LIKE '%K'     THEN CAST(REPLACE("volume",'K','') AS REAL) * 1000
            WHEN "volume" LIKE '%M'     THEN CAST(REPLACE("volume",'M','') AS REAL) * 1000000
            ELSE CAST("volume" AS REAL)
        END AS "volume_numeric"
    FROM "bitcoin_prices"
),
aug_days AS (
    SELECT
        v1."ticker",
        v1."market_date",
        v1."volume_numeric"                                       AS "vol_today",
        (
            SELECT v2."volume_numeric"
            FROM   volumes v2
            WHERE  v2."ticker" = v1."ticker"
              AND  v2."market_date" < v1."market_date"
              AND  v2."volume_numeric" > 0                       -- skip zero volumes
            ORDER  BY v2."market_date" DESC
            LIMIT 1
        )                                                        AS "vol_prev"
    FROM volumes v1
    WHERE v1."market_date" BETWEEN '01-08-2021' AND '10-08-2021'
)
SELECT
    "ticker",
    "market_date",
    ROUND(100.0 * ("vol_today" - "vol_prev") / "vol_prev", 4)    AS "pct_change_volume"
FROM   aug_days
WHERE  "vol_today" > 0
  AND  "vol_prev"  > 0
ORDER  BY "ticker",
          "market_date";