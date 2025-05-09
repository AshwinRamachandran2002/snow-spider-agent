SELECT
    EXTRACT(YEAR  FROM "month_start")                                   AS "YEAR",
    EXTRACT(MONTH FROM "month_start")                                   AS "MONTH",
    "monthly_tx_count"                                                  AS "MONTHLY_TRANSACTION_COUNT",
    ROUND("monthly_tx_count" / "seconds_in_month", 4)                   AS "TRANSACTIONS_PER_SECOND"
FROM (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000))  AS "month_start",
        COUNT(*)                                                        AS "monthly_tx_count",
        DATEDIFF(
            'second',
            DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000)),
            DATEADD('month', 1, DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000)))
        )                                                               AS "seconds_in_month"
    FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS"
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
    GROUP BY "month_start"
)
ORDER BY "MONTHLY_TRANSACTION_COUNT" DESC NULLS LAST;