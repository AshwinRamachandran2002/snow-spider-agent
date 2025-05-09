/*  Magnificent 7 – % change in post-market close price
    from the first trading day on/after 1-Jan-2024
    to the last trading day on/before 30-Jun-2024             */

WITH mag7 AS (   -- ticker list
    SELECT 'AAPL' AS "TICKER" UNION ALL
    SELECT 'MSFT' UNION ALL
    SELECT 'GOOGL' UNION ALL
    SELECT 'AMZN' UNION ALL
    SELECT 'META' UNION ALL
    SELECT 'NVDA' UNION ALL
    SELECT 'TSLA'
),

/* first trading date ≥ 2024-01-01 holding a post-market close price */
first_trade AS (
    SELECT s."TICKER",
           MIN(s."DATE") AS "START_DATE"
    FROM FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES"  s
    JOIN mag7                                                   USING ("TICKER")
    WHERE s."VARIABLE" = 'post-market_close'
      AND s."DATE"    >= '2024-01-01'
    GROUP BY s."TICKER"
),

/* price on that first trading date */
start_prices AS (
    SELECT s."TICKER",
           s."VALUE" AS "START_PRICE"
    FROM FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES"  s
    JOIN first_trade                                           f
      ON s."TICKER" = f."TICKER"
     AND s."DATE"   = f."START_DATE"
    WHERE s."VARIABLE" = 'post-market_close'
),

/* last trading date ≤ 2024-06-30 holding a post-market close price */
last_trade AS (
    SELECT s."TICKER",
           MAX(s."DATE") AS "END_DATE"
    FROM FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES"  s
    JOIN mag7                                                   USING ("TICKER")
    WHERE s."VARIABLE" = 'post-market_close'
      AND s."DATE"    <= '2024-06-30'
    GROUP BY s."TICKER"
),

/* price on that last trading date */
end_prices AS (
    SELECT s."TICKER",
           s."VALUE" AS "END_PRICE"
    FROM FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES"  s
    JOIN last_trade                                            l
      ON s."TICKER" = l."TICKER"
     AND s."DATE"   = l."END_DATE"
    WHERE s."VARIABLE" = 'post-market_close'
)

/* final %-change calculation */
SELECT sp."TICKER",
       sp."START_PRICE",
       ep."END_PRICE",
       ROUND(
           100 * (ep."END_PRICE" - sp."START_PRICE") / sp."START_PRICE",
           4
       ) AS "PERCENT_CHANGE_JAN1_TO_JUN30_2024"
FROM start_prices sp
JOIN end_prices  ep  USING ("TICKER")
ORDER BY sp."TICKER";