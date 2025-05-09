WITH per_ticker AS (
    SELECT
        "TICKER",
        MIN_BY("VALUE","DATE") AS "START_PRICE",   -- first post-market close price in 2024-01-01 to 2024-06-30 window
        MAX_BY("VALUE","DATE") AS "END_PRICE"      -- last  post-market close price in same window
    FROM FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES"
    WHERE "VARIABLE" = 'post-market_close'
      AND "TICKER" IN ('AAPL','AMZN','GOOGL','MSFT','META','NVDA','TSLA')   -- Magnificent 7 tech tickers
      AND "DATE" BETWEEN '2024-01-01' AND '2024-06-30'
    GROUP BY "TICKER"
)

SELECT
    "TICKER",
    "START_PRICE",
    "END_PRICE",
    ROUND( ( "END_PRICE" - "START_PRICE" ) / NULLIF("START_PRICE",0) * 100 , 2 ) AS "PERCENT_CHANGE_JAN1_TO_JUN30_2024"
FROM per_ticker
ORDER BY "PERCENT_CHANGE_JAN1_TO_JUN30_2024" DESC NULLS LAST;