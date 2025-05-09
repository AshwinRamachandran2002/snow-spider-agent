WITH daily_amounts AS (
    SELECT
        DATE_TRUNC('DAY', TO_TIMESTAMP_NTZ("block_timestamp", 6))::DATE AS "tx_date",
        "amount"                                                AS "amount"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
)
SELECT
    "tx_date",
    SUM("amount") AS "total_transaction_amount"
FROM daily_amounts
WHERE "tx_date" < DATE '2022-01-01'
GROUP BY "tx_date"
ORDER BY "total_transaction_amount" DESC NULLS LAST
LIMIT 1;