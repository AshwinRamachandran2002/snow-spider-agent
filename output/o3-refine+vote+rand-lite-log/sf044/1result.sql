WITH ranked AS (
    SELECT
        "TICKER",
        "DATE",
        "VALUE",
        ROW_NUMBER() OVER (PARTITION BY "TICKER" ORDER BY "DATE" ASC)  AS rn_start,
        ROW_NUMBER() OVER (PARTITION BY "TICKER" ORDER BY "DATE" DESC) AS rn_end
    FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
    WHERE "VARIABLE" = 'post-market_close'
      AND "TICKER" IN ('AAPL','MSFT','NVDA','AMZN','GOOGL','META','TSLA')
      AND "DATE" BETWEEN '2024-01-01' AND '2024-06-30'
),

starts AS (
    SELECT
        "TICKER",
        "DATE"  AS start_date,
        "VALUE" AS start_price
    FROM ranked
    WHERE rn_start = 1
),

ends AS (
    SELECT
        "TICKER",
        "DATE"  AS end_date,
        "VALUE" AS end_price
    FROM ranked
    WHERE rn_end = 1
)

SELECT
    s."TICKER",
    s.start_date,
    s.start_price,
    e.end_date,
    e.end_price,
    ROUND( (e.end_price - s.start_price) / s.start_price * 100 , 4) AS pct_change_from_2024_01_01_to_2024_06_30
FROM starts s
JOIN ends   e
  ON s."TICKER" = e."TICKER"
ORDER BY s."TICKER";