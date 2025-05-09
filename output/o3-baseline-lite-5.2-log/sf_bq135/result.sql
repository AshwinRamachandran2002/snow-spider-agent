SELECT 
    CAST(TO_TIMESTAMP("block_timestamp" / 1000000) AS DATE)                               AS "date",
    SUM("amount")                                                                        AS "total_transaction_amount"
FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
WHERE CAST(TO_TIMESTAMP("block_timestamp" / 1000000) AS DATE) < '2022-01-01'
GROUP BY "date"
ORDER BY "total_transaction_amount" DESC NULLS LAST, "date" ASC
LIMIT 1;