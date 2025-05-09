WITH monthly_logs AS (
    SELECT
        DATE_PART('year',  TO_TIMESTAMP("block_timestamp" / 1000000)) AS "YEAR",
        DATE_PART('month', TO_TIMESTAMP("block_timestamp" / 1000000)) AS "MONTH"
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."LOGS"
    WHERE DATE_PART('year', TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
)

SELECT
    COUNT(*)                                                                  AS "MONTHLY_TRANSACTION_COUNT",
    ROUND(
        COUNT(*) /
        DATEDIFF(
            'second',
            DATE_FROM_PARTS("YEAR", "MONTH", 1),
            DATEADD('month', 1, DATE_FROM_PARTS("YEAR", "MONTH", 1))
        ),
        4
    )                                                                         AS "TRANSACTIONS_PER_SECOND",
    "YEAR",
    "MONTH"
FROM monthly_logs
GROUP BY "YEAR", "MONTH"
ORDER BY "MONTHLY_TRANSACTION_COUNT" DESC NULLS LAST;