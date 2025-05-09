WITH ref_dates AS (
    -- target comparison dates
    SELECT '2024-01-01'::DATE AS ref_date, 'start' AS period
    UNION ALL
    SELECT '2024-06-30'::DATE,          'end'   AS period
),
prices AS (
    SELECT
        p."TICKER",
        r.period,
        p."VALUE",
        ROW_NUMBER() OVER (
            PARTITION BY p."TICKER", r.period
            ORDER BY p."DATE" DESC      -- pick the latest trading day ≤ ref_date
        ) AS rn
    FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES  p
    JOIN ref_dates r
      ON p."DATE" <= r.ref_date
    WHERE p."VARIABLE" = 'post-market_close'
      AND p."TICKER"  IN ('AAPL','MSFT','AMZN','GOOGL','NVDA','META','TSLA')   -- Magnificent 7
),
selected AS (
    SELECT "TICKER", period, "VALUE"
    FROM   prices
    QUALIFY rn = 1                     -- keep just the chosen record per period
)
SELECT
    s0."TICKER",
    ROUND( (s1."VALUE" - s0."VALUE") / s0."VALUE" * 100 , 4) AS "PERCENT_CHANGE_JAN1_TO_JUN30_2024"
FROM   selected s0      -- start (≈ 2024‑01‑02)
JOIN   selected s1
  ON   s0."TICKER" = s1."TICKER"
WHERE  s0.period = 'start'
  AND  s1.period = 'end'
ORDER BY "PERCENT_CHANGE_JAN1_TO_JUN30_2024" DESC NULLS LAST;