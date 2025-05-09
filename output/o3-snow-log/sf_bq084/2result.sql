WITH monthly_counts AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000))  AS month_start ,   -- first day of month (00:00:00)
        COUNT(*)                                                       AS monthly_transaction_count
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS
    WHERE EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
    GROUP BY month_start
)

SELECT
    monthly_transaction_count,
    ROUND(
        monthly_transaction_count 
        / DATEDIFF(
              'second',
              month_start,
              DATEADD('month', 1, month_start)           -- exact seconds in the month
          ),
        4
    )                                                   AS transactions_per_second,
    EXTRACT(year  FROM month_start)                     AS year,
    EXTRACT(month FROM month_start)                     AS month
FROM monthly_counts
ORDER BY monthly_transaction_count DESC NULLS LAST;