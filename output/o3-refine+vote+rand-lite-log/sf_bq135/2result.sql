WITH daily_totals AS (
    SELECT
        CAST(TO_TIMESTAMP("block_timestamp" / 1000000) AS DATE)     AS "tx_date",
        SUM("amount")                                              AS "total_amount"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE TO_TIMESTAMP("block_timestamp" / 1000000) < TO_TIMESTAMP('2022-01-01')
    GROUP BY CAST(TO_TIMESTAMP("block_timestamp" / 1000000) AS DATE)
)
SELECT
    "tx_date",
    "total_amount"
FROM daily_totals
ORDER BY "total_amount" DESC NULLS LAST
LIMIT 1;