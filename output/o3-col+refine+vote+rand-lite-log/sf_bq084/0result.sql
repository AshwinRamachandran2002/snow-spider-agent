WITH logs_2023 AS (
    /* 1. Keep every 2023 log row and derive its month (micro-seconds ➜ seconds ➜ timestamp). */
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000)) AS "month_start"
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS
    WHERE "block_timestamp" >= 1672531200 * 1000000   -- 2023-01-01 00:00:00
      AND "block_timestamp" <  1704067200 * 1000000   -- 2024-01-01 00:00:00
),
/* 2. Count every (non-deduped) transaction record per month. */
monthly_counts AS (
    SELECT
        "month_start",
        COUNT(*) AS "monthly_tx_count"
    FROM logs_2023
    GROUP BY "month_start"
),
/* 3. Compute the exact number of seconds each month spans. */
monthly_seconds AS (
    SELECT
        "month_start",
        DATEDIFF('second', "month_start", DATEADD(month, 1, "month_start")) AS "seconds_in_month"
    FROM monthly_counts
)
/* 4. Combine, calculate TPS, and present results. */
SELECT
    YEAR(mc."month_start")                        AS "year",
    MONTH(mc."month_start")                       AS "month",
    mc."monthly_tx_count"                         AS "monthly_transaction_count",
    mc."monthly_tx_count"::FLOAT
        / ms."seconds_in_month"                   AS "tx_per_second"
FROM monthly_counts   mc
JOIN monthly_seconds  ms USING ("month_start")
ORDER BY mc."monthly_tx_count" DESC NULLS LAST;