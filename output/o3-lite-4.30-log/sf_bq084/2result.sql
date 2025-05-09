WITH logs_2023 AS (
    SELECT
        TO_TIMESTAMP("block_timestamp" / 1000000) AS ts
    FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS"
    WHERE EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
),
monthly_counts AS (
    SELECT
        EXTRACT(year  FROM ts)                       AS year,
        EXTRACT(month FROM ts)                       AS month,
        COUNT(*)                                     AS monthly_transaction_count,
        DATE_TRUNC('month', ts)                      AS month_start
    FROM logs_2023
    GROUP BY 1, 2, 4
),
seconds_per_month AS (
    SELECT
        month_start,
        DATEDIFF('second', month_start, DATEADD('month', 1, month_start)) AS seconds_in_month
    FROM monthly_counts
)
SELECT
    mc.year,
    mc.month,
    mc.monthly_transaction_count,
    ROUND(mc.monthly_transaction_count / spm.seconds_in_month, 4) AS transactions_per_second
FROM monthly_counts mc
JOIN seconds_per_month spm
      ON mc.month_start = spm.month_start
ORDER BY mc.monthly_transaction_count DESC NULLS LAST,
         mc.month              DESC NULLS LAST;