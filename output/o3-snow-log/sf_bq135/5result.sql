WITH daily_totals AS (
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) AS "tx_date",
        SUM("amount")                               AS "total_amount"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "block_timestamp" IS NOT NULL
      AND TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) < '2022-01-01'
    GROUP BY TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))
)
SELECT
    "tx_date"          -- date with the highest total amount before 2022
FROM daily_totals
ORDER BY "total_amount" DESC NULLS LAST
LIMIT 1;