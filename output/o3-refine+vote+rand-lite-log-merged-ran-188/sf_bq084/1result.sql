WITH per_row AS (
    /* convert micro‑second timestamps to TIMESTAMP and keep only rows from 2023 */
    SELECT 
        TO_TIMESTAMP("block_timestamp" / 1000000)          AS ts
    FROM   GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."LOGS"
    WHERE  EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
), per_month AS (
    /* aggregate rows by month and compute seconds in the month */
    SELECT
        DATE_TRUNC('MONTH', ts)                                                 AS month_start,
        COUNT(*)                                                                AS monthly_tx_count,
        DATEDIFF('SECOND',
                DATE_TRUNC('MONTH', ts),
                DATEADD('MONTH', 1, DATE_TRUNC('MONTH', ts)) )                 AS seconds_in_month
    FROM   per_row
    GROUP  BY month_start
)
SELECT
    EXTRACT(YEAR  FROM month_start)                                            AS year,
    EXTRACT(MONTH FROM month_start)                                            AS month,
    monthly_tx_count,
    monthly_tx_count / seconds_in_month                                        AS transactions_per_second
FROM   per_month
ORDER  BY monthly_tx_count DESC NULLS LAST,
          month_start      DESC;