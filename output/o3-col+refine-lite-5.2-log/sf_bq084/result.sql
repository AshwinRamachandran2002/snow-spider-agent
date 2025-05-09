WITH base AS (
    SELECT
        TO_TIMESTAMP_LTZ("block_timestamp" / 1000000) AS ts
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."LOGS"
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP_LTZ("block_timestamp" / 1000000)) = 2023
),
monthly AS (
    SELECT
        EXTRACT(YEAR  FROM ts) AS "year",
        EXTRACT(MONTH FROM ts) AS "month",
        COUNT(*) AS "monthly_txn_cnt",
        DATEDIFF(
            'second',
            DATE_TRUNC('month', MIN(ts)),
            DATEADD('month', 1, DATE_TRUNC('month', MIN(ts)))
        ) AS "sec_in_month"
    FROM base
    GROUP BY
        EXTRACT(YEAR FROM ts),
        EXTRACT(MONTH FROM ts)
)
SELECT
    "year",
    "month",
    "monthly_txn_cnt",
    ROUND("monthly_txn_cnt" / "sec_in_month", 4) AS "txn_per_sec"
FROM monthly
ORDER BY
    "monthly_txn_cnt" DESC NULLS LAST,
    "month" ASC;