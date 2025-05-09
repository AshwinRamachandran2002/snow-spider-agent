SELECT
    TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) AS "date",
    ROUND(SUM("amount"), 4)                           AS total_transaction_amount_zil
FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
WHERE "block_timestamp" < 1640995200000000      -- before 2022‑01‑01
GROUP BY "date"
ORDER BY total_transaction_amount_zil DESC
LIMIT 1;