WITH transactions_2023 AS (
    SELECT
        TO_TIMESTAMP("block_timestamp" / 1000000)                                  AS ts,          -- convert μs to TIMESTAMP
        DATE_TRUNC('MONTH', TO_TIMESTAMP("block_timestamp" / 1000000))             AS month_start  -- first day of the month
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."LOGS"
    WHERE YEAR(TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023                   -- keep only 2023
)

SELECT
    YEAR(month_start)                                               AS "YEAR",
    MONTH(month_start)                                              AS "MONTH",
    COUNT(*)                                                        AS "MONTHLY_TRANSACTION_COUNT",
    COUNT(*) / DATEDIFF('second', month_start, DATEADD('MONTH', 1, month_start))::FLOAT
                                                                    AS "TRANSACTIONS_PER_SECOND"
FROM transactions_2023
GROUP BY month_start
ORDER BY "MONTHLY_TRANSACTION_COUNT" DESC NULLS LAST, "MONTH" DESC;