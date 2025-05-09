WITH start_dates AS (  -- first trading day on/after 1-Jan-2024
    SELECT
        "TICKER",
        MIN("DATE") AS "START_DATE"
    FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
    WHERE "VARIABLE" = 'post-market_close'
      AND "TICKER" IN ('AAPL','MSFT','AMZN','GOOGL','META','NVDA','TSLA')
      AND "DATE" >= '2024-01-01' AND "DATE" <= '2024-06-30'
    GROUP BY "TICKER"
),
end_dates AS (  -- last trading day on/before 30-Jun-2024
    SELECT
        "TICKER",
        MAX("DATE") AS "END_DATE"
    FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
    WHERE "VARIABLE" = 'post-market_close'
      AND "TICKER" IN ('AAPL','MSFT','AMZN','GOOGL','META','NVDA','TSLA')
      AND "DATE" >= '2024-01-01' AND "DATE" <= '2024-06-30'
    GROUP BY "TICKER"
)
SELECT
    s."TICKER",
    st."VALUE" AS "START_PRICE",
    et."VALUE" AS "END_PRICE",
    ROUND(100 * (et."VALUE" - st."VALUE") / st."VALUE", 2) AS "PCT_CHANGE_JAN1_TO_JUN30_2024"
FROM start_dates s
JOIN end_dates e
  ON s."TICKER" = e."TICKER"
JOIN FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES st
  ON st."TICKER" = s."TICKER"
 AND st."DATE"   = s."START_DATE"
 AND st."VARIABLE" = 'post-market_close'
JOIN FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES et
  ON et."TICKER" = e."TICKER"
 AND et."DATE"   = e."END_DATE"
 AND et."VARIABLE" = 'post-market_close'
ORDER BY s."TICKER";