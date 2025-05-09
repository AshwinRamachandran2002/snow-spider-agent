WITH transactions_per_day AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))              AS "tx_date",
        TO_NUMBER("amount")                                             AS "amount"
    FROM
        CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE
        "block_timestamp" IS NOT NULL
        AND "amount" IS NOT NULL
)
SELECT
    "tx_date",
    SUM("amount") AS "total_transaction_amount"
FROM
    transactions_per_day
WHERE
    "tx_date" < '2022-01-01'
GROUP BY
    "tx_date"
ORDER BY
    "total_transaction_amount" DESC NULLS LAST,
    "tx_date"
LIMIT 1;