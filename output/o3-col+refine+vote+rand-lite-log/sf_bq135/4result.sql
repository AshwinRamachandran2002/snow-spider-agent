SELECT
    TO_DATE( TO_TIMESTAMP("block_timestamp" / 1000000) ) AS "highest_amount_date",
    SUM("amount")                                        AS "total_amount"
FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
WHERE "success" = TRUE
  AND TO_DATE( TO_TIMESTAMP("block_timestamp" / 1000000) ) < '2022-01-01'
GROUP BY "highest_amount_date"
ORDER BY "total_amount" DESC NULLS LAST
LIMIT 1;