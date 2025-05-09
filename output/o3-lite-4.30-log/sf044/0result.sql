WITH prices AS (
    SELECT
        "TICKER",
        MIN_BY("VALUE", "DATE") AS first_price,
        MAX_BY("VALUE", "DATE") AS last_price
    FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
    WHERE "VARIABLE" = 'post-market_close'
      AND "TICKER" IN ('AAPL','MSFT','AMZN','GOOGL','META','NVDA','TSLA')
      AND "DATE" BETWEEN '2024-01-01' AND '2024-06-30'
    GROUP BY "TICKER"
)
SELECT
    "TICKER"                                                     AS ticker,
    ROUND((last_price - first_price) / first_price * 100, 4)     AS percentage_change
FROM prices
ORDER BY ticker;