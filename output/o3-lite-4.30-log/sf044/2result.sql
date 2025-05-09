WITH data_window AS (
    SELECT
        "TICKER",
        "DATE",
        "VALUE",
        MIN("DATE") OVER (PARTITION BY "TICKER") AS "FIRST_DATE",
        MAX("DATE") OVER (PARTITION BY "TICKER") AS "LAST_DATE"
    FROM "FINANCE__ECONOMICS"."CYBERSYN"."STOCK_PRICE_TIMESERIES"
    WHERE "VARIABLE" = 'post-market_close'
      AND "TICKER" IN ('AAPL','MSFT','GOOGL','AMZN','META','TSLA','NVDA')
      AND "DATE" BETWEEN '2024-01-01' AND '2024-06-30'
)

SELECT
    "TICKER" AS ticker,
    ROUND(
        (
            MAX(CASE WHEN "DATE" = "LAST_DATE"  THEN "VALUE" END) -
            MAX(CASE WHEN "DATE" = "FIRST_DATE" THEN "VALUE" END)
        )
        / MAX(CASE WHEN "DATE" = "FIRST_DATE" THEN "VALUE" END) * 100
    , 4) AS percentage_change
FROM data_window
GROUP BY "TICKER"
ORDER BY "TICKER";