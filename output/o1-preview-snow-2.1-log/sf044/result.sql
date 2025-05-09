WITH price_data AS (
    SELECT 
        "TICKER",
        "DATE",
        "VALUE" AS "price"
    FROM 
        FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
    WHERE 
        "VARIABLE" = 'post-market_close'
        AND "TICKER" IN ('AAPL', 'MSFT', 'AMZN', 'GOOGL', 'META', 'TSLA', 'NVDA')
        AND "DATE" BETWEEN '2024-01-01' AND '2024-06-30'
),
starting_prices AS (
    SELECT 
        "TICKER",
        "price" AS "start_price"
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY "TICKER" ORDER BY "DATE" ASC NULLS LAST) AS rn
        FROM price_data
    )
    WHERE rn = 1
),
ending_prices AS (
    SELECT 
        "TICKER",
        "price" AS "end_price"
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY "TICKER" ORDER BY "DATE" DESC NULLS LAST) AS rn
        FROM price_data
    )
    WHERE rn = 1
)
SELECT 
    s."TICKER",
    s."start_price",
    e."end_price",
    ROUND(((e."end_price" - s."start_price") / s."start_price") * 100, 4) AS "percentage_change"
FROM starting_prices s
JOIN ending_prices e ON s."TICKER" = e."TICKER";