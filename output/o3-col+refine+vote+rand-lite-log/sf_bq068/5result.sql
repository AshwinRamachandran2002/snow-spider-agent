/*  Maximum & minimum per-address final balances by address type  
    Bitcoin Cash transactions between 2014-03-01 and 2014-04-01          */

WITH tx_window AS (                 -- all tx-hashes inside the date window
    SELECT "hash"
    FROM   CRYPTO.CRYPTO_BITCOIN_CASH.TRANSACTIONS
    WHERE  "block_timestamp" >= 1393632000000000      -- 2014-03-01 00:00 UTC
       AND "block_timestamp" <  1396310400000000      -- 2014-04-01 00:00 UTC
),
movements AS (                      -- credits (+) from outputs, debits (−) from inputs
    SELECT
        o."addresses"          AS "address",
        o."type"               AS "address_type",
        o."value"              AS "amount"           -- credit
    FROM   CRYPTO.CRYPTO_BITCOIN_CASH.OUTPUTS  o
    JOIN   tx_window                            t ON o."transaction_hash" = t."hash"

    UNION ALL

    SELECT
        i."addresses"          AS "address",
        i."type"               AS "address_type",
       -i."value"              AS "amount"           -- debit (negative)
    FROM   CRYPTO.CRYPTO_BITCOIN_CASH.INPUTS   i
    JOIN   tx_window                            t ON i."transaction_hash" = t."hash"
),
per_address AS (                    -- final balance per individual address & type
    SELECT
        "address",
        "address_type",
        SUM("amount")        AS "final_balance"
    FROM   movements
    GROUP BY "address", "address_type"
)

SELECT
    "address_type",
    MAX("final_balance") AS "max_final_balance",
    MIN("final_balance") AS "min_final_balance"
FROM   per_address
GROUP BY "address_type"
ORDER BY "address_type";