WITH base AS (
    SELECT
        "TICKER",
        "DATE",
        "VALUE"
    FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
    WHERE "VARIABLE" = 'post-market_close'
      AND "TICKER" IN ('AAPL', 'MSFT', 'AMZN', 'GOOGL', 'META', 'NVDA', 'TSLA')
      AND "DATE" BETWEEN '2024-01-01' AND '2024-06-30'
),
start_vals AS (
    SELECT
        "TICKER",
        "VALUE" AS start_value
    FROM base
    QUALIFY "DATE" = MIN("DATE") OVER (PARTITION BY "TICKER")
),
end_vals AS (
    SELECT
        "TICKER",
        "VALUE" AS end_value
    FROM base
    QUALIFY "DATE" = MAX("DATE") OVER (PARTITION BY "TICKER")
)
SELECT
    s."TICKER",
    ROUND( (e.end_value - s.start_value) / s.start_value * 100, 4) AS "PERCENT_CHANGE_POST_MARKET_CLOSE_JAN1_TO_JUN30_2024"
FROM start_vals s
JOIN end_vals e USING ("TICKER")
ORDER BY "PERCENT_CHANGE_POST_MARKET_CLOSE_JAN1_TO_JUN30_2024" DESC NULLS LAST,
         s."TICKER";