WITH monthly AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000))          AS "month_start",
        COUNT(*)                                                                AS "transaction_count"
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS
    WHERE YEAR(TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
    GROUP BY DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000))
)

SELECT
    YEAR("month_start")                                                         AS "year",
    MONTH("month_start")                                                        AS "month",
    "transaction_count",
    ROUND(
        "transaction_count" /
        DATEDIFF(
            'second',
            "month_start",
            DATEADD('month', 1, "month_start")
        ),
        4
    )                                                                           AS "transactions_per_second"
FROM monthly
ORDER BY "transaction_count" DESC NULLS LAST, "year", "month";