SELECT
    dt                        AS "date",
    total_amount              AS "total_transaction_amount"
FROM (
    SELECT
        CAST(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS DATE) AS dt,
        SUM("amount") AS total_amount
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE CAST(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS DATE) < '2022-01-01'
    GROUP BY dt
)
ORDER BY total_amount DESC NULLS LAST
LIMIT 1;