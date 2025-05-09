SELECT 
    tran_date,
    total_transaction_amount
FROM (
    SELECT
        CAST(DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6)) AS DATE)  AS tran_date,
        SUM("amount")                                                           AS total_transaction_amount
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE TO_TIMESTAMP("block_timestamp" / 1e6) < '2022-01-01'::TIMESTAMP
    GROUP BY tran_date
)
ORDER BY total_transaction_amount DESC NULLS LAST, tran_date
LIMIT 1;