WITH tickers AS (   -- Magnificent 7 tickers
    SELECT column1 AS "TICKER"
    FROM ( VALUES
        ('AAPL'), ('MSFT'), ('GOOGL'), ('AMZN'),
        ('META'), ('NVDA'), ('TSLA')
    )
),

-- limit to post-market close quotes between Jan-1 and Jun-30 2024
quotes AS (
    SELECT  s."TICKER",
            s."DATE",
            s."VALUE"
    FROM    FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES  s
    JOIN    tickers t ON t."TICKER" = s."TICKER"
    WHERE   s."VARIABLE" = 'post-market_close'
      AND   s."DATE" BETWEEN '2024-01-01' AND '2024-06-30'
),

first_trade AS (    -- first trading day on/after Jan-1
    SELECT  "TICKER",
            MIN("DATE") AS "START_DATE"
    FROM    quotes
    GROUP BY "TICKER"
),

last_trade AS (     -- last trading day on/before Jun-30
    SELECT  "TICKER",
            MAX("DATE") AS "END_DATE"
    FROM    quotes
    GROUP BY "TICKER"
),

start_prices AS (
    SELECT  q."TICKER",
            q."VALUE" AS "START_PRICE"
    FROM    quotes q
    JOIN    first_trade f
        ON  q."TICKER" = f."TICKER"
       AND q."DATE"   = f."START_DATE"
),

end_prices AS (
    SELECT  q."TICKER",
            q."VALUE" AS "END_PRICE"
    FROM    quotes q
    JOIN    last_trade l
        ON  q."TICKER" = l."TICKER"
       AND q."DATE"   = l."END_DATE"
)

SELECT  sp."TICKER",
        ft."START_DATE",
        lt."END_DATE",
        sp."START_PRICE",
        ep."END_PRICE",
        ROUND( (ep."END_PRICE" - sp."START_PRICE") / sp."START_PRICE" * 100, 4)
            AS "PCT_CHANGE_JAN1_TO_JUN30_2024"
FROM        start_prices sp
JOIN        end_prices  ep ON ep."TICKER" = sp."TICKER"
JOIN        first_trade ft ON ft."TICKER" = sp."TICKER"
JOIN        last_trade  lt ON lt."TICKER" = sp."TICKER"
ORDER BY    sp."TICKER";