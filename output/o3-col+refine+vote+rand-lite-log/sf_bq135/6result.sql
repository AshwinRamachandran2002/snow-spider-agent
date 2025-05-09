SELECT 
    tx_date, 
    total_amount
FROM (
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) AS tx_date,
        SUM("amount") AS total_amount
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE TO_TIMESTAMP("block_timestamp" / 1000000) < '2022-01-01'
    GROUP BY tx_date
)
ORDER BY total_amount DESC NULLS LAST
LIMIT 1;