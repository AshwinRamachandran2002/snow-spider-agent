SELECT
    DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6)) AS "peak_date",
    SUM("amount")                                           AS "total_amount"
FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
WHERE TO_TIMESTAMP("block_timestamp" / 1e6) < '2022-01-01'::TIMESTAMP
GROUP BY 1
ORDER BY "total_amount" DESC NULLS LAST
LIMIT 1;