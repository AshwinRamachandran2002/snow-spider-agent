SELECT
    TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) AS "date",
    SUM("amount")                                    AS "total_transaction_amount"
FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
WHERE "block_timestamp" < 1640995200000000   -- before 2022-01-01 00:00:00 UTC
GROUP BY "date"
ORDER BY "total_transaction_amount" DESC NULLS LAST
LIMIT 1;