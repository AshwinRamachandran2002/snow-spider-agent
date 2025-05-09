WITH daily_totals AS (
    SELECT
        DATE_TRUNC(
            'DAY',
            TO_TIMESTAMP("block_timestamp" / 1000000)   -- convert µs epoch to timestamp
        )                         AS "date",
        "amount"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
)
SELECT
    "date",
    SUM("amount") AS "total_transaction_amount"
FROM daily_totals
WHERE "date" < DATE '2022-01-01'          -- only dates before 2022
GROUP BY "date"
ORDER BY "total_transaction_amount" DESC NULLS LAST,
         "date"
LIMIT 1;