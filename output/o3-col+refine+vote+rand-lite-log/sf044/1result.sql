/* Percentage change in post-market close prices for the Magnificent 7
   from Jan 1 to Jun 30 2024                                           */

WITH bounds AS (
    SELECT
        "TICKER",
        MIN(CASE WHEN "DATE" >= '2024-01-01' THEN "DATE" END) AS "START_DATE",
        MAX(CASE WHEN "DATE" <= '2024-06-30' THEN "DATE" END) AS "END_DATE"
    FROM FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES"
    WHERE "VARIABLE" = 'post-market_close'
      AND "TICKER" IN ('AAPL','MSFT','AMZN','META','NVDA','TSLA','GOOGL')
    GROUP BY "TICKER"
),
start_vals AS (
    SELECT
        b."TICKER",
        s."VALUE" AS "START_VALUE"
    FROM bounds b
    JOIN FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES" s
      ON s."TICKER" = b."TICKER"
     AND s."DATE"   = b."START_DATE"
    WHERE s."VARIABLE" = 'post-market_close'
),
end_vals AS (
    SELECT
        b."TICKER",
        s."VALUE" AS "END_VALUE"
    FROM bounds b
    JOIN FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES" s
      ON s."TICKER" = b."TICKER"
     AND s."DATE"   = b."END_DATE"
    WHERE s."VARIABLE" = 'post-market_close'
)

SELECT
    s."TICKER",
    s."START_VALUE",
    e."END_VALUE",
    ROUND( (e."END_VALUE" - s."START_VALUE") / s."START_VALUE" * 100, 2 )
        AS "PERCENT_CHANGE_JAN1_TO_JUN30_2024"
FROM start_vals s
JOIN end_vals  e USING ("TICKER")
ORDER BY "PERCENT_CHANGE_JAN1_TO_JUN30_2024" DESC NULLS LAST;