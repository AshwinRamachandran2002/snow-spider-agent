-- Date (before 2022) with the highest total Zilliqa transaction amount
SELECT
    "tx_date",
    "daily_total_amount"
FROM (
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))       AS "tx_date",
        SUM("amount")                                            AS "daily_total_amount"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) < 2022
    GROUP BY "tx_date"
)
ORDER BY "daily_total_amount" DESC NULLS LAST
LIMIT 1;