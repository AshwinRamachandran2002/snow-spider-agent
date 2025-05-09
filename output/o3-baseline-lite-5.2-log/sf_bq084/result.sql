WITH logs_2023 AS (
    SELECT
        TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS ts          -- convert μs → seconds → timestamp
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS
    WHERE YEAR(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) = 2023 -- keep only 2023 data
),
monthly_agg AS (
    SELECT
        YEAR(ts)  AS "YEAR",
        MONTH(ts) AS "MONTH",
        COUNT(*)  AS "MONTHLY_TRANSACTION_COUNT",
        DATEDIFF(                                               -- exact seconds in the month
            'second',
            DATE_TRUNC('month', MIN(ts)),                       -- first second of the month
            DATEADD('month', 1, DATE_TRUNC('month', MIN(ts)))   -- first second of next month
        ) AS "SECONDS_IN_MONTH"
    FROM logs_2023
    GROUP BY YEAR(ts), MONTH(ts)
)
SELECT
    "YEAR",
    "MONTH",
    "MONTHLY_TRANSACTION_COUNT",
    ROUND("MONTHLY_TRANSACTION_COUNT" / "SECONDS_IN_MONTH", 4) AS "TRANSACTIONS_PER_SECOND"
FROM monthly_agg
ORDER BY
    "MONTHLY_TRANSACTION_COUNT" DESC NULLS LAST,
    "YEAR",
    "MONTH";