WITH txs AS (
    /* Keep every log row (no de-duplication of transaction_hash)
       and restrict to the year 2023                                   */
    SELECT
        TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS ts
    FROM   GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."LOGS"
    WHERE  YEAR(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) = 2023
),
monthly AS (
    /* Aggregate by month */
    SELECT
        DATE_TRUNC('month', ts)                AS month_start,
        COUNT(*)                               AS monthly_transaction_count
    FROM   txs
    GROUP BY month_start
)
SELECT
    YEAR(month_start)                                                AS "year",
    MONTH(month_start)                                               AS "month",
    monthly_transaction_count,
    /* seconds in the month = difference between first day of next
       month and first day of this month; divide to get TPS          */
    ROUND(
        monthly_transaction_count /
        DATEDIFF(
            'second',
            month_start,
            DATEADD('month', 1, month_start)
        ),
        4
    )                                                                AS "transactions_per_second"
FROM   monthly
ORDER BY monthly_transaction_count DESC NULLS LAST;