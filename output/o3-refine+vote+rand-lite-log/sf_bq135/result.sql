SELECT
    tx_date                                           AS "date_with_highest_total_amount_before_2022",
    SUM_AMOUNT                                        AS "total_transaction_amount"
FROM (
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))   AS tx_date,
        SUM("amount")                                        AS SUM_AMOUNT
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) < '2022-01-01'
    GROUP BY tx_date
)
ORDER BY SUM_AMOUNT DESC NULLS LAST, tx_date
LIMIT 1;