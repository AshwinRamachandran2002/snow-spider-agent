-- Percentage change in post‑market close prices for the Magnificent 7
WITH first_trade AS (
    SELECT
        "TICKER",
        MIN("DATE") AS "FIRST_DATE"
    FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
    WHERE "VARIABLE" = 'post-market_close'
      AND "TICKER" IN ('AAPL','MSFT','AMZN','GOOG','META','TSLA','NVDA')
      AND "DATE" >= '2024-01-01'
    GROUP BY "TICKER"
),
first_prices AS (
    SELECT
        s."TICKER",
        f."FIRST_DATE",
        s."VALUE" AS "FIRST_VALUE"
    FROM first_trade f
    JOIN FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES s
      ON s."TICKER" = f."TICKER"
     AND s."DATE"   = f."FIRST_DATE"
    WHERE s."VARIABLE" = 'post-market_close'
),
last_trade AS (
    SELECT
        "TICKER",
        MAX("DATE") AS "LAST_DATE"
    FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
    WHERE "VARIABLE" = 'post-market_close'
      AND "TICKER" IN ('AAPL','MSFT','AMZN','GOOG','META','TSLA','NVDA')
      AND "DATE" <= '2024-06-30'
    GROUP BY "TICKER"
),
last_prices AS (
    SELECT
        s."TICKER",
        l."LAST_DATE",
        s."VALUE" AS "LAST_VALUE"
    FROM last_trade l
    JOIN FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES s
      ON s."TICKER" = l."TICKER"
     AND s."DATE"   = l."LAST_DATE"
    WHERE s."VARIABLE" = 'post-market_close'
)
SELECT
    f."TICKER",
    f."FIRST_DATE",
    f."FIRST_VALUE",
    l."LAST_DATE",
    l."LAST_VALUE",
    100 * (l."LAST_VALUE" - f."FIRST_VALUE") / f."FIRST_VALUE" AS "PCT_CHANGE_H1_2024"
FROM first_prices f
JOIN last_prices  l ON f."TICKER" = l."TICKER"
ORDER BY f."TICKER";