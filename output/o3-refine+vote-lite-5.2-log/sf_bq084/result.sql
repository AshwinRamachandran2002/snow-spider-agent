WITH logs_2023 AS (
    SELECT
        TO_TIMESTAMP("block_timestamp" / 1000000)        AS ts
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."LOGS"
    WHERE EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
),
monthly_counts AS (
    SELECT
        EXTRACT(year  FROM ts)                          AS "year",
        EXTRACT(month FROM ts)                          AS "month",
        COUNT(*)                                        AS tx_count
    FROM logs_2023
    GROUP BY 1, 2
)
SELECT
    tx_count                                           AS "monthly_transaction_count",
    ROUND(
        tx_count / DATEDIFF(
            'second',
            DATE_FROM_PARTS("year","month",1),
            DATEADD(month,1,DATE_FROM_PARTS("year","month",1))
        ),
        4
    )                                                  AS "transactions_per_second",
    "year",
    "month"
FROM monthly_counts
ORDER BY "monthly_transaction_count" DESC NULLS LAST,
         "year",
         "month";