WITH endpoints AS (
    /* 1.  Identify the first and last trading-day dates available
            between 2024-01-01 and 2024-06-30 for each Magnificent-7 ticker */
    SELECT
        "TICKER",
        MIN("DATE") AS "START_DATE",
        MAX("DATE") AS "END_DATE"
    FROM FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES"
    WHERE "VARIABLE" = 'post-market_close'
      AND "TICKER" IN ('AAPL','MSFT','GOOGL','GOOG','AMZN','META','TSLA','NVDA')
      AND "DATE" BETWEEN '2024-01-01' AND '2024-06-30'
    GROUP BY "TICKER"
),
prices AS (
    /* 2.  Grab the post-market close price on those start/end dates */
    SELECT
        e."TICKER",
        s_start."VALUE" AS "START_VAL",
        s_end."VALUE"   AS "END_VAL"
    FROM endpoints e
    /* start-of-period price */
    LEFT JOIN FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES" s_start
           ON s_start."TICKER"   = e."TICKER"
          AND s_start."VARIABLE" = 'post-market_close'
          AND s_start."DATE"     = e."START_DATE"
    /* end-of-period price */
    LEFT JOIN FINANCE__ECONOMICS.CYBERSYN."STOCK_PRICE_TIMESERIES" s_end
           ON s_end."TICKER"     = e."TICKER"
          AND s_end."VARIABLE"   = 'post-market_close'
          AND s_end."DATE"       = e."END_DATE"
)
SELECT
    "TICKER",
    "START_VAL"        AS "PRICE_2024_01_01_PLUS",
    "END_VAL"          AS "PRICE_2024_06_30",
    ROUND( (("END_VAL" - "START_VAL") / "START_VAL") * 100 , 2) AS "PERCENT_CHANGE"
FROM prices
ORDER BY "TICKER";