WITH tx_entries AS (

    /* + credits (outputs) */
    SELECT
        a.value::STRING                        AS "ADDRESS",
        o."type"                               AS "ADDRESS_TYPE",
        CAST(o."value" AS NUMBER)              AS "AMOUNT"          -- credit
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS"  o
         ,LATERAL FLATTEN( INPUT => o."addresses") a
    WHERE o."block_timestamp" >= 1393632000000000     -- 2014‑03‑01 00:00:00 UTC
      AND o."block_timestamp" <  1396310400000000     -- 2014‑04‑01 00:00:00 UTC

    UNION ALL

    /* − debits (inputs) */
    SELECT
        a.value::STRING                        AS "ADDRESS",
        i."type"                               AS "ADDRESS_TYPE",
        -CAST(i."value" AS NUMBER)             AS "AMOUNT"          -- debit
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"   i
         ,LATERAL FLATTEN( INPUT => i."addresses") a
    WHERE i."block_timestamp" >= 1393632000000000
      AND i."block_timestamp" <  1396310400000000
),

address_balances AS (
    /* final balance per address (within the period) */
    SELECT
        "ADDRESS_TYPE",
        "ADDRESS",
        SUM("AMOUNT")                          AS "FINAL_BALANCE"
    FROM tx_entries
    GROUP BY "ADDRESS_TYPE", "ADDRESS"
)

SELECT
    "ADDRESS_TYPE",
    MAX("FINAL_BALANCE") AS "MAX_FINAL_BALANCE",
    MIN("FINAL_BALANCE") AS "MIN_FINAL_BALANCE"
FROM address_balances
GROUP BY "ADDRESS_TYPE"
ORDER BY "ADDRESS_TYPE";