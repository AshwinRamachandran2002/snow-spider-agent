SELECT
  TO_TIMESTAMP("block_timestamp" / 1000000)::DATE AS "date",
  SUM("amount")                                   AS "total_transaction_amount_zil"
FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
WHERE "block_timestamp" < 1640995200000000   -- 2022‑01‑01 00:00:00 UTC in µs
GROUP BY "date"
ORDER BY "total_transaction_amount_zil" DESC NULLS LAST
LIMIT 1;