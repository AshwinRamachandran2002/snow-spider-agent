WITH first_price AS (
    SELECT
        "TICKER",
        MIN("DATE")                                     AS "FIRST_DATE",
        MIN_BY("VALUE", "DATE")                         AS "FIRST_PRICE"
    FROM FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES"
    WHERE "VARIABLE_NAME" = 'Post-Market Close'
      AND "TICKER" IN ('AAPL','MSFT','GOOG','GOOGL','AMZN','META','NVDA','TSLA')  -- Magnificent 7 (+ both Alphabet share classes)
      AND "DATE" >= '2024-01-01'
    GROUP BY "TICKER"
),
last_price AS (
    SELECT
        "TICKER",
        MAX("DATE")                                     AS "LAST_DATE",
        MAX_BY("VALUE", "DATE")                         AS "LAST_PRICE"
    FROM FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES"
    WHERE "VARIABLE_NAME" = 'Post-Market Close'
      AND "TICKER" IN ('AAPL','MSFT','GOOG','GOOGL','AMZN','META','NVDA','TSLA')
      AND "DATE" <= '2024-06-30'
    GROUP BY "TICKER"
)
SELECT
    f."TICKER",
    f."FIRST_DATE",
    f."FIRST_PRICE",
    l."LAST_DATE",
    l."LAST_PRICE",
    (l."LAST_PRICE" - f."FIRST_PRICE") / f."FIRST_PRICE" * 100 AS "PCT_CHANGE_JAN1_TO_JUN30_2024"
FROM first_price f
JOIN last_price l USING ("TICKER")
ORDER BY "TICKER";