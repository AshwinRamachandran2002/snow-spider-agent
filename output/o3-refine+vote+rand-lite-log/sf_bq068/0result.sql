WITH
/* credits: transaction outputs (positive) */
"outputs" AS (
    SELECT
        "type"           AS "address_type",
        SUM("value")     AS "balance"          -- credit
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS"
    WHERE "block_timestamp" >= 1393632000000000   -- 2014‑03‑01 00:00:00 UTC
      AND "block_timestamp" <  1396310400000000   -- 2014‑04‑01 00:00:00 UTC
    GROUP BY "type"
),
/* debits: transaction inputs (negative) */
"inputs" AS (
    SELECT
        "type"           AS "address_type",
        -SUM("value")    AS "balance"          -- debit (negative)
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"
    WHERE "block_timestamp" >= 1393632000000000
      AND "block_timestamp" <  1396310400000000
    GROUP BY "type"
),
/* merge debits and credits */
"combined" AS (
    SELECT * FROM "outputs"
    UNION ALL
    SELECT * FROM "inputs"
),
/* final balance per address type */
"final_balances" AS (
    SELECT
        "address_type",
        SUM("balance") AS "final_balance"
    FROM "combined"
    GROUP BY "address_type"
)
/* maximum and minimum final balances across address types */
SELECT
    MAX("final_balance") AS "max_final_balance",
    MIN("final_balance") AS "min_final_balance"
FROM "final_balances";