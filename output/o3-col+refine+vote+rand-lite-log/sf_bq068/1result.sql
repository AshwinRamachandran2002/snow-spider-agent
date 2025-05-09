WITH "all_moves" AS (
    /* credits = outputs, debits = -inputs within the date range */
    SELECT
        "type",
        "value"::NUMBER AS "amount"                 -- credit
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS"
    WHERE "block_timestamp" >= 1393632000000000    -- 2014-03-01
      AND "block_timestamp" <  1396310400000000    -- 2014-04-01

    UNION ALL

    SELECT
        "type",
        - "value"::NUMBER AS "amount"               -- debit
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"
    WHERE "block_timestamp" >= 1393632000000000
      AND "block_timestamp" <  1396310400000000
),
"balances" AS (
    /* running balance (credits − debits) per address type */
    SELECT
        "type",
        SUM("amount") AS "final_balance"
    FROM "all_moves"
    GROUP BY "type"
)
SELECT
    MAX("final_balance") AS "max_balance",
    MIN("final_balance") AS "min_balance"
FROM "balances";