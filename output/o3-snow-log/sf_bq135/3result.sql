WITH daily_totals AS (
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))      AS "tx_date",   -- convert µs to date
        "amount"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
)
SELECT
    "tx_date",
    SUM("amount") AS "total_transaction_amount"
FROM daily_totals
WHERE "tx_date" < '2022-01-01'          -- only dates before 2022
GROUP BY "tx_date"
ORDER BY "total_transaction_amount" DESC NULLS LAST
LIMIT 1;