WITH tickers AS (
    /*  Magnificent 7 tickers list  */
    SELECT column1 AS "TICKER"
    FROM (VALUES 
          ('AAPL'),('MSFT'),('AMZN'),
          ('GOOGL'),('META'),('NVDA'),('TSLA'))
),

bounds AS (
    /*  First trading date ≥ 2024-01-01 and
        last trading date ≤ 2024-06-30 for each ticker  */
    SELECT  s."TICKER",
            MIN(s."DATE") AS "FIRST_DATE",
            MAX(s."DATE") AS "LAST_DATE"
    FROM    FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES"  s
    JOIN    tickers t
      ON    s."TICKER" = t."TICKER"
    WHERE   s."VARIABLE" = 'post-market_close'
      AND   s."DATE" BETWEEN '2024-01-01' AND '2024-06-30'
    GROUP BY s."TICKER"
),

first_price AS (
    SELECT  b."TICKER",
            s."DATE",
            s."VALUE" AS "FIRST_PRICE"
    FROM    bounds b
    JOIN    FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES" s
      ON    s."TICKER" = b."TICKER"
      AND   s."DATE"   = b."FIRST_DATE"
    WHERE   s."VARIABLE" = 'post-market_close'
),

last_price AS (
    SELECT  b."TICKER",
            s."DATE",
            s."VALUE" AS "LAST_PRICE"
    FROM    bounds b
    JOIN    FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES" s
      ON    s."TICKER" = b."TICKER"
      AND   s."DATE"   = b."LAST_DATE"
    WHERE   s."VARIABLE" = 'post-market_close'
)

SELECT  f."TICKER",
        f."DATE"  AS "FIRST_DATE",
        l."DATE"  AS "LAST_DATE",
        f."FIRST_PRICE",
        l."LAST_PRICE",
        100 * (l."LAST_PRICE" - f."FIRST_PRICE") / f."FIRST_PRICE" 
            AS "PCT_CHANGE_JAN1_TO_JUN30_2024"
FROM    first_price f
JOIN    last_price  l USING ("TICKER")
ORDER BY f."TICKER";