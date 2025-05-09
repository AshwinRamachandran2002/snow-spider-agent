-- Percentage change in post-market close prices for the Magnificent-7
-- from the first trading day of Jan-2024 to the last trading day of Jun-2024
WITH january_start AS (
    SELECT
        "TICKER",
        "DATE",
        "VALUE" AS "start_price",
        ROW_NUMBER() OVER (PARTITION BY "TICKER" ORDER BY "DATE") AS rn
    FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
    WHERE "TICKER" IN ('AAPL','MSFT','AMZN','GOOGL','META','TSLA','NVDA')
      AND "VARIABLE" = 'post-market_close'
      AND "DATE" BETWEEN '2024-01-01' AND '2024-01-31'
),
june_end AS (
    SELECT
        "TICKER",
        "DATE",
        "VALUE" AS "end_price",
        ROW_NUMBER() OVER (PARTITION BY "TICKER" ORDER BY "DATE" DESC) AS rn
    FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
    WHERE "TICKER" IN ('AAPL','MSFT','AMZN','GOOGL','META','TSLA','NVDA')
      AND "VARIABLE" = 'post-market_close'
      AND "DATE" BETWEEN '2024-06-01' AND '2024-06-30'
)
SELECT
    s."TICKER",
    s."DATE" AS "start_date",
    e."DATE" AS "end_date",
    s."start_price",
    e."end_price",
    ROUND((e."end_price" - s."start_price") / s."start_price" * 100, 2) AS "percent_change"
FROM january_start s
JOIN june_end   e USING ("TICKER")
WHERE s.rn = 1
  AND e.rn = 1
ORDER BY "percent_change" DESC;