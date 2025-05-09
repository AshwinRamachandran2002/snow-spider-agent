-- Date before 2022 with the highest total Zilliqa transaction amount
SELECT
    TO_TIMESTAMP("block_timestamp" / 1000000)::DATE AS "tx_date",
    SUM("amount")                                   AS "total_amount"
FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
WHERE "block_timestamp" < 1640995200000000      -- 2022-01-01 00:00:00 UTC in µs
GROUP BY 1
ORDER BY "total_amount" DESC NULLS LAST
LIMIT 1;