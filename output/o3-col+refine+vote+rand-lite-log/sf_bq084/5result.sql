WITH logs_2023 AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000)) AS month_start
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."LOGS"
    WHERE TO_TIMESTAMP("block_timestamp" / 1000000) >= '2023-01-01'
      AND TO_TIMESTAMP("block_timestamp" / 1000000) <  '2024-01-01'
),
monthly AS (
    SELECT
        month_start,
        COUNT(*) AS monthly_transaction_count,
        DATEDIFF('second', month_start, DATEADD('month', 1, month_start)) AS seconds_in_month
    FROM logs_2023
    GROUP BY month_start
)
SELECT
    EXTRACT(YEAR  FROM month_start)                             AS "year",
    EXTRACT(MONTH FROM month_start)                             AS "month",
    monthly_transaction_count                                   AS "monthly_transaction_count",
    ROUND(monthly_transaction_count / seconds_in_month::FLOAT, 4) AS "transactions_per_second"
FROM monthly
ORDER BY monthly_transaction_count DESC NULLS LAST;