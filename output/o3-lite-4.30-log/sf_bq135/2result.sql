SELECT
       DATE_TRUNC('day', TO_TIMESTAMP_LTZ("block_timestamp"/1000000))::date AS "date",
       ROUND(SUM("amount"), 4)                                             AS "total_transaction_amount_zil"
FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
WHERE  "block_timestamp" < 1640995200 * 1000000   -- before 2022‑01‑01 (µs)
GROUP  BY "date"
ORDER  BY "total_transaction_amount_zil" DESC NULLS LAST, "date"
LIMIT  1;