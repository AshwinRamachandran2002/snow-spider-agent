SELECT
    current."ticker",
    current."market_date",
    ROUND(((current."volume_numeric" - previous."volume_numeric") * 100.0 / previous."volume_numeric"), 4) AS "percentage_change_in_volume"
FROM (
    SELECT
        "ticker",
        "market_date",
        date(substr("market_date", 7, 4) || '-' || substr("market_date", 4, 2) || '-' || substr("market_date", 1, 2)) AS "date_formatted",
        CASE
            WHEN "volume" LIKE '%K' THEN CAST(REPLACE("volume", 'K', '') AS REAL) * 1000
            WHEN "volume" LIKE '%M' THEN CAST(REPLACE("volume", 'M', '') AS REAL) * 1000000
            WHEN "volume" = '-' THEN 0
            ELSE CAST("volume" AS REAL)
        END AS "volume_numeric"
    FROM "bitcoin_prices"
) AS current
JOIN (
    SELECT
        "ticker",
        "market_date",
        date(substr("market_date", 7, 4) || '-' || substr("market_date", 4, 2) || '-' || substr("market_date", 1, 2)) AS "date_formatted",
        CASE
            WHEN "volume" LIKE '%K' THEN CAST(REPLACE("volume", 'K', '') AS REAL) * 1000
            WHEN "volume" LIKE '%M' THEN CAST(REPLACE("volume", 'M', '') AS REAL) * 1000000
            WHEN "volume" = '-' THEN 0
            ELSE CAST("volume" AS REAL)
        END AS "volume_numeric"
    FROM "bitcoin_prices"
) AS previous
ON current."ticker" = previous."ticker"
   AND current."date_formatted" = date(previous."date_formatted", '+1 day')
WHERE current."date_formatted" BETWEEN '2021-08-01' AND '2021-08-10'
  AND previous."volume_numeric" > 0
ORDER BY current."ticker", current."date_formatted";