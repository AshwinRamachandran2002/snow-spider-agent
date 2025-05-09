WITH months_2023 AS (   -- build a 12‑row list of 2023 months + exact seconds in each month
    SELECT
        DATE_TRUNC('month', DATEADD('month', SEQ4(), DATE '2023-01-01')) AS month_start,
        DATEDIFF(
            'second',
            DATE_TRUNC('month', DATEADD('month', SEQ4(), DATE '2023-01-01')),
            DATEADD('month', 1, DATE_TRUNC('month', DATEADD('month', SEQ4(), DATE '2023-01-01')))
        ) AS seconds_in_month
    FROM TABLE(GENERATOR(ROWCOUNT => 12))
),
tx_by_month AS (        -- count every log row (no hash de‑duplication) per month in 2023
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1e6)) AS month_start,
        COUNT(*)                                                   AS monthly_transaction_count
    FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS"
    WHERE "block_timestamp" >= 1672531200000000  -- 2023‑01‑01 00:00:00 UTC (µs)
      AND "block_timestamp" <  1704067200000000  -- 2024‑01‑01 00:00:00 UTC (µs)
    GROUP BY month_start
)
SELECT
    YEAR(m.month_start)                                        AS year,
    MONTH(m.month_start)                                       AS month,
    t.monthly_transaction_count,
    ROUND(t.monthly_transaction_count / m.seconds_in_month::FLOAT, 4) AS transactions_per_second
FROM months_2023 m
JOIN tx_by_month t USING (month_start)
ORDER BY t.monthly_transaction_count DESC NULLS LAST,
         m.month_start;