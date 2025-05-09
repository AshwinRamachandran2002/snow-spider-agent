WITH daily_totals AS (
    SELECT
        TO_DATE( TO_TIMESTAMP( "block_timestamp" / 1000000 ) ) AS "tx_date",
        SUM( "amount" )                                       AS "total_amount"
    FROM CRYPTO.CRYPTO_ZILLIQA."TRANSACTIONS"
    WHERE "block_timestamp" < 1640995200000000   -- 2022‑01‑01 in micro‑seconds
    GROUP BY "tx_date"
)
SELECT
    "tx_date",
    "total_amount"
FROM daily_totals
ORDER BY
    "total_amount" DESC NULLS LAST,
    "tx_date"      ASC
LIMIT 1;