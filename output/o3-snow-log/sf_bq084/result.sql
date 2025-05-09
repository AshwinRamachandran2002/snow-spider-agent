WITH tx_data AS (
    /* keep every log row (no deduplication) and convert micro-seconds to a real timestamp */
    SELECT
        TO_TIMESTAMP("block_timestamp" / 1000000) AS ts
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS
    WHERE EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
),
monthly AS (
    SELECT
        EXTRACT(year  FROM ts) AS year,
        EXTRACT(month FROM ts) AS month,
        COUNT(*)               AS monthly_tx_count,
        /* exact length of that month in seconds */
        DATEDIFF(
            'second',
            DATE_TRUNC('month', MIN(ts)),
            DATEADD('month', 1, DATE_TRUNC('month', MIN(ts)))
        )                      AS seconds_in_month
    FROM tx_data
    GROUP BY 1, 2
)
SELECT
    year,
    month,
    monthly_tx_count,
    ROUND(monthly_tx_count / seconds_in_month, 4) AS tx_per_second
FROM monthly
ORDER BY monthly_tx_count DESC NULLS LAST;