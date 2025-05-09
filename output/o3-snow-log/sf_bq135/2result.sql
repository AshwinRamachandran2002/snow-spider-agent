WITH daily_totals AS (
    SELECT
        CAST(DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1000000)) AS DATE) AS "tx_date",
        SUM("amount")                                        AS "daily_amount"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1000000)) < '2022-01-01'
    GROUP BY "tx_date"
)
SELECT
    "tx_date"        AS "date_with_highest_total_amount",
    "daily_amount"   AS "total_transaction_amount"
FROM daily_totals
ORDER BY "daily_amount" DESC NULLS LAST
LIMIT 1;