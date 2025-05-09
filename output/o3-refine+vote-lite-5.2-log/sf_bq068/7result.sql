WITH
-- credits  (= outputs)
credits AS (
    SELECT
        addr.value::STRING                         AS "address",
        o."type"                                   AS "address_type",
        SUM(o."value")                             AS "amount"          -- positive
    FROM CRYPTO.CRYPTO_BITCOIN_CASH.OUTPUTS o,
         LATERAL FLATTEN(input => o."addresses")   addr
    WHERE o."block_timestamp" >= 1393632000000000      -- 2014‑03‑01 00:00:00 UTC
      AND o."block_timestamp" <  1396310400000000      -- 2014‑04‑01 00:00:00 UTC
    GROUP BY addr.value, o."type"
),

-- debits (= inputs)
debits AS (
    SELECT
        addr.value::STRING                         AS "address",
        i."type"                                   AS "address_type",
        -SUM(i."value")                            AS "amount"          -- negative
    FROM CRYPTO.CRYPTO_BITCOIN_CASH.INPUTS  i,
         LATERAL FLATTEN(input => i."addresses")   addr
    WHERE i."block_timestamp" >= 1393632000000000
      AND i."block_timestamp" <  1396310400000000
    GROUP BY addr.value, i."type"
),

-- ledger: sum of all movements per address
ledger AS (
    SELECT * FROM credits
    UNION ALL
    SELECT * FROM debits
),

balance_per_address AS (
    SELECT
        "address_type",
        "address",
        SUM("amount") AS "final_balance"
    FROM ledger
    GROUP BY "address_type", "address"
)

-- maximum and minimum final balances per address type
SELECT
    "address_type",
    MAX("final_balance") AS "max_final_balance",
    MIN("final_balance") AS "min_final_balance"
FROM balance_per_address
GROUP BY "address_type"
ORDER BY "address_type";