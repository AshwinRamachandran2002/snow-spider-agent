-- Task: Using the "bitcoin_prices" table, adjust the 'volume' column values by converting volumes ending with 'K' to thousands, volumes ending with 'M' to millions, treating any '-' volume as zero, and casting other volumes as REAL numbers. Display the 'ticker', 'market_date', and adjusted 'volume' for the first 100 records.

SELECT
  "ticker",
  "market_date",
  CASE
    WHEN RIGHT("volume", 1) = 'K' THEN CAST(LEFT("volume", LENGTH("volume") - 1) AS REAL) * 1000
    WHEN RIGHT("volume", 1) = 'M' THEN CAST(LEFT("volume", LENGTH("volume") - 1) AS REAL) * 1000000
    WHEN "volume" = '-' THEN 0
    ELSE CAST("volume" AS REAL)
  END AS "volume"
FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_PRICES"
LIMIT 100;