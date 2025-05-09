WITH bounds AS (
    SELECT 
        "TICKER",
        MIN("DATE") AS "START_DATE",
        MAX("DATE") AS "END_DATE"
    FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
    WHERE "VARIABLE" = 'post-market_close'
      AND "TICKER" IN ('AAPL','MSFT','GOOGL','AMZN','META','TSLA','NVDA')   -- Magnificent 7 tickers
      AND "DATE" BETWEEN '2024-01-01' AND '2024-06-30'
    GROUP BY "TICKER"
), start_prices AS (
    SELECT 
        b."TICKER",
        s."VALUE" AS "START_PRICE"
    FROM bounds b
    JOIN FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES s
      ON s."TICKER" = b."TICKER"
     AND s."VARIABLE" = 'post-market_close'
     AND s."DATE" = b."START_DATE"
), end_prices AS (
    SELECT 
        b."TICKER",
        s."VALUE" AS "END_PRICE"
    FROM bounds b
    JOIN FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES s
      ON s."TICKER" = b."TICKER"
     AND s."VARIABLE" = 'post-market_close'
     AND s."DATE" = b."END_DATE"
)
SELECT 
    sp."TICKER",
    sp."START_PRICE",
    ep."END_PRICE",
    ROUND( (ep."END_PRICE" - sp."START_PRICE") / sp."START_PRICE" * 100 , 4) AS "PERCENT_CHANGE_JAN1_TO_JUN30_2024"
FROM start_prices sp
JOIN end_prices  ep USING ("TICKER")
ORDER BY "PERCENT_CHANGE_JAN1_TO_JUN30_2024" DESC NULLS LAST, "TICKER";