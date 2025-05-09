SELECT
    DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "Month",
    COUNT(DISTINCT "transaction_hash") AS "Transaction_Count",
    ROUND(
        COUNT(DISTINCT "transaction_hash") /
        DATEDIFF(
            'SECOND',
            DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)),
            DATEADD('MONTH', 1, DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)))
        ),
        4
    ) AS "Transactions_Per_Second"
FROM
    GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS
WHERE
    TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) >= '2023-01-01'
    AND TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) < '2024-01-01'
GROUP BY
    "Month"
ORDER BY
    "Transaction_Count" DESC NULLS LAST;