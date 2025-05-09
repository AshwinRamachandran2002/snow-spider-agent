WITH
-- first post-market close on/after 1-Jan-2024
start_price AS (
    SELECT "TICKER",
           "VALUE" AS "P_START"
    FROM (
        SELECT  "TICKER",
                "VALUE",
                ROW_NUMBER() OVER (PARTITION BY "TICKER" ORDER BY "DATE") AS rn
        FROM    FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES"
        WHERE   "VARIABLE" = 'post-market_close'
          AND   "TICKER"  IN ('AAPL','MSFT','AMZN','NVDA','GOOGL','META','TSLA')
          AND   "DATE"   >= '2024-01-01'
    )
    WHERE rn = 1
),
-- last post-market close on/before 30-Jun-2024
end_price AS (
    SELECT "TICKER",
           "VALUE" AS "P_END"
    FROM (
        SELECT  "TICKER",
                "VALUE",
                ROW_NUMBER() OVER (PARTITION BY "TICKER" ORDER BY "DATE" DESC) AS rn
        FROM    FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES"
        WHERE   "VARIABLE" = 'post-market_close'
          AND   "TICKER"  IN ('AAPL','MSFT','AMZN','NVDA','GOOGL','META','TSLA')
          AND   "DATE"   <= '2024-06-30'
    )
    WHERE rn = 1
)
SELECT  s."TICKER",
        ROUND( (e."P_END" - s."P_START") / s."P_START" * 100 , 2) AS "PERCENT_CHANGE_%"
FROM    start_price s
JOIN    end_price  e USING ("TICKER")
ORDER BY s."TICKER";