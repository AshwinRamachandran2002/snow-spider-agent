/*  Max-vs-Min net balances per Bitcoin-Cash script type
    window: 2014-03-01 00:00:00  → 2014-04-01 00:00:00  (µs-epoch) */

WITH ledger AS (               -- double-entry view
    ------------------------------------------------------------------
    /* credits – transaction outputs (positive) */
    SELECT
        f.value::STRING        AS "address",
        o."type"               AS "addr_type",
        o."value"::NUMBER      AS "amount_signed"
    FROM  CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS" o,
          LATERAL FLATTEN(INPUT => o."addresses") f
    WHERE o."block_timestamp" BETWEEN 1393632000000000    -- 2014-03-01
                                 AND     1396310400000000  -- 2014-04-01

    UNION ALL
    ------------------------------------------------------------------
    /* debits – transaction inputs (negative) */
    SELECT
        f.value::STRING        AS "address",
        i."type"               AS "addr_type",
       -i."value"::NUMBER      AS "amount_signed"
    FROM  CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"  i,
          LATERAL FLATTEN(INPUT => i."addresses") f
    WHERE i."block_timestamp" BETWEEN 1393632000000000
                                 AND     1396310400000000
),
balances AS (                   -- net balance per address
    SELECT
        "address",
        MIN("addr_type")       AS "addr_type",   -- representative script-type
        SUM("amount_signed")   AS "final_balance"
    FROM   ledger
    GROUP BY "address"
)
SELECT
    "addr_type",
    MAX("final_balance") AS "max_final_balance",
    MIN("final_balance") AS "min_final_balance"
FROM   balances
GROUP BY "addr_type"
ORDER BY "addr_type";