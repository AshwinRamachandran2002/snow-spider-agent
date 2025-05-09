SELECT
    tx_date AS "DATE_WITH_HIGHEST_TOTAL_AMOUNT_BEFORE_2022",
    total_amount
FROM (
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))  AS tx_date,
        SUM("amount")                                       AS total_amount
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "block_timestamp" < 1640995200000000   -- 2022-01-01 00:00:00 UTC in µs
    GROUP BY tx_date
)
ORDER BY total_amount DESC NULLS LAST
LIMIT 1;