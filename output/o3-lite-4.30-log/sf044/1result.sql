SELECT
    "TICKER"                                                                  AS ticker,
    ROUND( (MAX_BY("VALUE","DATE") - MIN_BY("VALUE","DATE")) 
           / MIN_BY("VALUE","DATE") * 100 , 4 )                               AS percentage_change
FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
WHERE "VARIABLE" = 'post-market_close'
  AND "TICKER" IN ('AAPL','MSFT','AMZN','GOOGL','META','NVDA','TSLA')
  AND "DATE" BETWEEN '2024-01-01' AND '2024-06-30'
GROUP BY "TICKER"
ORDER BY ticker;