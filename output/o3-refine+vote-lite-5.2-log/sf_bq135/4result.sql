WITH daily_amounts AS (
    SELECT
        CAST(DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1000000)) AS DATE) AS "txn_date",
        "amount"::NUMBER AS "amount"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
)
SELECT
    "txn_date" AS "date",
    SUM("amount") AS "total_transaction_amount"
FROM daily_amounts
WHERE "txn_date" < '2022-01-01'
GROUP BY "txn_date"
ORDER BY "total_transaction_amount" DESC NULLS LAST
LIMIT 1;