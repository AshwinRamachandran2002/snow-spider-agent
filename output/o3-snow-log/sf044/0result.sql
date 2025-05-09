WITH h1_prices AS (
    SELECT
        "TICKER",
        "DATE",
        "VALUE"
    FROM FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES"
    WHERE "VARIABLE" = 'post-market_close'
      AND "TICKER" IN ('AAPL','AMZN','MSFT','GOOG','META','NVDA','TSLA')
      AND "DATE" BETWEEN '2024-01-01' AND '2024-06-30'
), first_last_dates AS (
    SELECT
        "TICKER",
        MIN("DATE") AS "FIRST_DATE",   -- first trading day on/after Jan-01-2024
        MAX("DATE") AS "LAST_DATE"     -- last trading day on/before Jun-30-2024
    FROM h1_prices
    GROUP BY "TICKER"
), first_last_prices AS (
    SELECT
        d."TICKER",
        p_start."VALUE" AS "FIRST_VALUE",
        p_end."VALUE"   AS "LAST_VALUE"
    FROM first_last_dates d
    JOIN h1_prices p_start
      ON p_start."TICKER" = d."TICKER"
     AND p_start."DATE"   = d."FIRST_DATE"
    JOIN h1_prices p_end
      ON p_end."TICKER"   = d."TICKER"
     AND p_end."DATE"     = d."LAST_DATE"
)
SELECT
    "TICKER",
    "FIRST_VALUE" AS "PRICE_JAN01_2024",
    "LAST_VALUE"  AS "PRICE_JUN30_2024",
    ROUND( ( "LAST_VALUE" - "FIRST_VALUE" ) / "FIRST_VALUE" * 100 , 2) AS "PCT_CHANGE_H1_2024"
FROM first_last_prices
ORDER BY "PCT_CHANGE_H1_2024" DESC NULLS LAST;