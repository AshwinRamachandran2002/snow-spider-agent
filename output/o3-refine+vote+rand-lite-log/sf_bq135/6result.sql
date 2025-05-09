SELECT 
    DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6))          AS "tx_date",
    SUM(TO_NUMBER("amount"))                                          AS "total_amount"
FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
WHERE "block_timestamp" < 1640995200000000          -- before 2022‑01‑01 (in µs)
GROUP BY "tx_date"
ORDER BY "total_amount" DESC NULLS LAST
LIMIT 1;