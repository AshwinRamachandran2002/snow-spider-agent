SELECT
    "tx_date",
    "daily_total_amount"
FROM (
    SELECT
        TO_TIMESTAMP("block_timestamp" / 1000000)::DATE AS "tx_date",
        SUM("amount") AS "daily_total_amount"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE TO_TIMESTAMP("block_timestamp" / 1000000) < '2022-01-01'
    GROUP BY "tx_date"
)
ORDER BY "daily_total_amount" DESC NULLS LAST
LIMIT 1;