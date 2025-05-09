/* Percentage change in post-market close prices for the Magnificent-7
   (AAPL, MSFT, AMZN, GOOGL, META, NVDA, TSLA) from 1-Jan-2024 to 30-Jun-2024 */

WITH filter_data AS (
    SELECT
        "TICKER",
        "VALUE",
        "DATE"
    FROM FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES"
    WHERE "VARIABLE" = 'post-market_close'
      AND "TICKER" IN ('AAPL','MSFT','AMZN','GOOGL','META','NVDA','TSLA')
      AND "DATE" BETWEEN '2024-01-01' AND '2024-06-30'
),
first_last AS (
    SELECT
        "TICKER",
        MIN_BY("VALUE", "DATE") AS "FIRST_PRICE",
        MAX_BY("VALUE", "DATE") AS "LAST_PRICE"
    FROM filter_data
    GROUP BY "TICKER"
)
SELECT
    "TICKER",
    "FIRST_PRICE",
    "LAST_PRICE",
    ROUND( ( "LAST_PRICE" - "FIRST_PRICE") / "FIRST_PRICE" * 100 , 4) AS "PCT_CHANGE_2024H1"
FROM first_last
ORDER BY "TICKER";