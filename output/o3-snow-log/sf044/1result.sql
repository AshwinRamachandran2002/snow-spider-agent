/*  Percentage change in post-market close prices for the Magnificent 7
    from the first trading day on/after 1-Jan-2024 to the last trading
    day on/before 30-Jun-2024                                        */

WITH start_price AS (
    SELECT
        "TICKER",
        "DATE"        AS "START_DATE",
        "VALUE"       AS "START_PRICE"
    FROM (
        SELECT
            "TICKER",
            "DATE",
            "VALUE",
            ROW_NUMBER() OVER (PARTITION BY "TICKER" ORDER BY "DATE") AS rn
        FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
        WHERE "VARIABLE" = 'post-market_close'
          AND "TICKER" IN ('AAPL','MSFT','NVDA','AMZN','GOOGL','META','TSLA')
          AND "DATE" >= '2024-01-01'
    )
    WHERE rn = 1
),
end_price AS (
    SELECT
        "TICKER",
        "DATE"        AS "END_DATE",
        "VALUE"       AS "END_PRICE"
    FROM (
        SELECT
            "TICKER",
            "DATE",
            "VALUE",
            ROW_NUMBER() OVER (PARTITION BY "TICKER" ORDER BY "DATE" DESC) AS rn
        FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
        WHERE "VARIABLE" = 'post-market_close'
          AND "TICKER" IN ('AAPL','MSFT','NVDA','AMZN','GOOGL','META','TSLA')
          AND "DATE" <= '2024-06-30'
    )
    WHERE rn = 1
)

SELECT
    s."TICKER",
    s."START_DATE",
    s."START_PRICE",
    e."END_DATE",
    e."END_PRICE",
    (e."END_PRICE" - s."START_PRICE") / s."START_PRICE" * 100
        AS "PCT_CHANGE_JAN1_TO_JUN30_2024"
FROM start_price s
JOIN end_price  e
  ON s."TICKER" = e."TICKER"
ORDER BY "TICKER";