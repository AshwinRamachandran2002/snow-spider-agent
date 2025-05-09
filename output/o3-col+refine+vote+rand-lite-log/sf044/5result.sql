/* Percentage change in post-market close prices for the “Magnificent 7”
   (AAPL, AMZN, GOOGL, META, MSFT, NVDA, TSLA)
   from the first trade on/after 1-Jan-2024 through the last trade on/before 30-Jun-2024. */

WITH traded AS (      -- restrict to relevant tickers, variable, and H1-2024 window
    SELECT  "TICKER",
            "DATE",
            "VALUE"
    FROM    FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
    WHERE   "VARIABLE" = 'post-market_close'
      AND   "TICKER" IN ('AAPL','AMZN','GOOGL','META','MSFT','NVDA','TSLA')
      AND   "DATE" BETWEEN '2024-01-01' AND '2024-06-30'
),
bounds AS (           -- find first & last available trading days in the period
    SELECT  "TICKER",
            MIN("DATE") AS start_date,
            MAX("DATE") AS end_date
    FROM    traded
    GROUP BY "TICKER"
),
start_prices AS (     -- grab the starting price
    SELECT  t."TICKER",
            t."VALUE" AS start_price
    FROM    traded t
    JOIN    bounds b
           ON t."TICKER" = b."TICKER"
          AND t."DATE"   = b.start_date
),
end_prices AS (       -- grab the ending price
    SELECT  t."TICKER",
            t."VALUE" AS end_price
    FROM    traded t
    JOIN    bounds b
           ON t."TICKER" = b."TICKER"
          AND t."DATE"   = b.end_date
)

SELECT  b."TICKER",
        b.start_date            AS "START_DATE",
        sp.start_price          AS "START_PRICE",
        b.end_date              AS "END_DATE",
        ep.end_price            AS "END_PRICE",
        ROUND( (ep.end_price - sp.start_price) / sp.start_price * 100 , 2) AS "PCT_CHANGE"
FROM    bounds       b
JOIN    start_prices sp USING ("TICKER")
JOIN    end_prices   ep USING ("TICKER")
ORDER BY b."TICKER";