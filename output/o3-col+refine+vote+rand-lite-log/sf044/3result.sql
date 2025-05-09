WITH magnificent_7 AS (
    SELECT COLUMN1 AS "TICKER"
    FROM VALUES 
        ('AAPL'), ('MSFT'), ('AMZN'), ('GOOGL'), ('META'), ('NVDA'), ('TSLA')
),

first_price AS (
    SELECT  
        s."TICKER",
        MIN(s."DATE")                                           AS "START_DATE",
        MIN_BY(s."VALUE", s."DATE")                             AS "START_PRICE"
    FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES s
    JOIN magnificent_7 m USING ("TICKER")
    WHERE s."VARIABLE" = 'post-market_close'
      AND s."DATE" >= '2024-01-01'
    GROUP BY s."TICKER"
),

last_price AS (
    SELECT  
        s."TICKER",
        MAX(s."DATE")                                           AS "END_DATE",
        MAX_BY(s."VALUE", s."DATE")                             AS "END_PRICE"
    FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES s
    JOIN magnificent_7 m USING ("TICKER")
    WHERE s."VARIABLE" = 'post-market_close'
      AND s."DATE" <= '2024-06-30'
    GROUP BY s."TICKER"
)

SELECT  
    f."TICKER",
    f."START_DATE",
    f."START_PRICE",
    l."END_DATE",
    l."END_PRICE",
    ROUND((l."END_PRICE" - f."START_PRICE") / f."START_PRICE" * 100, 2)  
        AS "PERCENT_CHANGE_JAN1_TO_JUN30_2024"
FROM first_price f
JOIN last_price l USING ("TICKER")
ORDER BY "TICKER";