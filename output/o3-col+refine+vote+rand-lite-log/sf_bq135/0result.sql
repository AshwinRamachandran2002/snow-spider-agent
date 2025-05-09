-- Date (before 2022-01-01) with the highest summed ZIL transfer amount
SELECT
    TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) AS "richest_date_before_2022",
    SUM("amount")                                      AS "max_total_amount"
FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
WHERE "block_timestamp" < 1640995200000000          -- 2022-01-01 in micro-seconds
GROUP BY 1
ORDER BY "max_total_amount" DESC NULLS LAST
LIMIT 1;