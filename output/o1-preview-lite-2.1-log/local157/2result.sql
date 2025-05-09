SELECT 
  "date" AS "Date", 
  "ticker" AS "Ticker", 
  ROUND( ( ("volume_numeric" - LAG("volume_numeric") OVER (PARTITION BY "ticker" ORDER BY "date")) / LAG("volume_numeric") OVER (PARTITION BY "ticker" ORDER BY "date") ) * 100, 4) AS "Percentage_Change"
FROM (
  SELECT 
    "ticker", 
    DATE(SUBSTR("market_date", 7, 4) || '-' || SUBSTR("market_date", 4, 2) || '-' || SUBSTR("market_date", 1, 2)) AS "date",
    CASE 
      WHEN SUBSTR("volume", -1) = 'K' THEN CAST(REPLACE(SUBSTR("volume", 1, LENGTH("volume") - 1), ',', '') AS REAL) * 1000
      WHEN SUBSTR("volume", -1) = 'M' THEN CAST(REPLACE(SUBSTR("volume", 1, LENGTH("volume") - 1), ',', '') AS REAL) * 1000000
      ELSE CAST(REPLACE("volume", ',', '') AS REAL)
    END AS "volume_numeric"
  FROM "bitcoin_prices"
  WHERE DATE(SUBSTR("market_date", 7, 4) || '-' || SUBSTR("market_date", 4, 2) || '-' || SUBSTR("market_date", 1, 2)) BETWEEN '2021-07-31' AND '2021-08-10'
) AS volumes
WHERE "date" BETWEEN '2021-08-01' AND '2021-08-10'
ORDER BY "date", "ticker";