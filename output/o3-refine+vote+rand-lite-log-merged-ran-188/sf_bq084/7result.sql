WITH monthly_counts AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000))     AS "MONTH_START",
        COUNT(*)                                                          AS "MONTHLY_TRANSACTION_COUNT"
    FROM
        GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."LOGS"
    WHERE
        EXTRACT('year', TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
    GROUP BY
        1
)
SELECT
    EXTRACT('year',  "MONTH_START")                                                    AS "YEAR",
    EXTRACT('month', "MONTH_START")                                                    AS "MONTH",
    "MONTHLY_TRANSACTION_COUNT",
    ROUND(
        "MONTHLY_TRANSACTION_COUNT" /
        NULLIF(
            DATEDIFF(
                'second',
                "MONTH_START",
                DATEADD('month', 1, "MONTH_START")
            ),
            0
        )
    , 4)                                                                               AS "TRANSACTIONS_PER_SECOND"
FROM
    monthly_counts
ORDER BY
    "MONTHLY_TRANSACTION_COUNT" DESC NULLS LAST,
    "MONTH"                 DESC;