WITH logs_2023 AS (
    /* 1.  Keep only 2023 log-rows and bucket them to the first day of their month */
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000)) AS "month_start"
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS
    WHERE YEAR(TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
),  

monthly AS (
    /* 2.  Aggregate by month and work out how many seconds each month contains */
    SELECT
        "month_start",
        COUNT(*)                                                   AS "monthly_transaction_count",
        DATEDIFF(
            'second',
            "month_start",
            DATEADD('month', 1, "month_start")
        )                                                          AS "seconds_in_month"
    FROM logs_2023
    GROUP BY "month_start"
)

SELECT
    "monthly_transaction_count",
    ROUND("monthly_transaction_count" / "seconds_in_month", 4)    AS "transactions_per_second",
    YEAR("month_start")                                           AS "year",
    MONTH("month_start")                                          AS "month"
FROM monthly
ORDER BY "monthly_transaction_count" DESC NULLS LAST;