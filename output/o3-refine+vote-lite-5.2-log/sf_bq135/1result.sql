SELECT
    txn_date                   AS "DATE",
    total_amount               AS "TOTAL_TRANSACTION_AMOUNT"
FROM (
    SELECT
        CAST(DATE_TRUNC('day',
              TO_TIMESTAMP("block_timestamp" / 1000000)) AS DATE)  AS txn_date,
        SUM("amount")                                                    AS total_amount
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE CAST(DATE_TRUNC('day',
              TO_TIMESTAMP("block_timestamp" / 1000000)) AS DATE) < '2022-01-01'
    GROUP BY txn_date
)
ORDER BY total_amount DESC NULLS LAST, txn_date
LIMIT 1;