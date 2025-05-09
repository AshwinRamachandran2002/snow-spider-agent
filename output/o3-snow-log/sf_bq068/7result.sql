WITH
/* +----------------------------------------------------------+
   | 1.  Credits : all outputs in the period (positive value) |
   +----------------------------------------------------------+ */
outputs_flat AS (
    SELECT
        o."type"                                   AS "ADDRESS_TYPE",
        f.value::string                            AS "ADDRESS",
        CAST(o."value" AS NUMBER(38,0))            AS "AMOUNT"        -- credit
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS" o,
         LATERAL FLATTEN(input => o."addresses") f
    WHERE o."block_timestamp" >= 1393632000000000   -- 2014-03-01 00:00:00 UTC
      AND o."block_timestamp" <  1396310400000000   -- 2014-04-01 00:00:00 UTC
),

/* +----------------------------------------------------------+
   | 2.  Debits : all inputs in the same period (negative)    |
   +----------------------------------------------------------+ */
inputs_flat AS (
    SELECT
        i."type"                                   AS "ADDRESS_TYPE",
        f.value::string                            AS "ADDRESS",
        -CAST(i."value" AS NUMBER(38,0))           AS "AMOUNT"        -- debit
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS" i,
         LATERAL FLATTEN(input => i."addresses") f
    WHERE i."block_timestamp" >= 1393632000000000   -- 2014-03-01
      AND i."block_timestamp" <  1396310400000000   -- 2014-04-01
),

/* +----------------------------------------------------------+
   | 3.  Net balance per address (credits – debits)           |
   +----------------------------------------------------------+ */
balances AS (
    SELECT
        "ADDRESS_TYPE",
        "ADDRESS",
        SUM("AMOUNT") AS "BALANCE"
    FROM (
        SELECT * FROM outputs_flat
        UNION ALL
        SELECT * FROM inputs_flat
    )
    GROUP BY "ADDRESS_TYPE", "ADDRESS"
)

/* +----------------------------------------------------------+
   | 4.  Max / Min final balances by address type             |
   +----------------------------------------------------------+ */
SELECT
    "ADDRESS_TYPE",
    MAX("BALANCE") AS "MAX_FINAL_BALANCE",
    MIN("BALANCE") AS "MIN_FINAL_BALANCE"
FROM balances
GROUP BY "ADDRESS_TYPE"
ORDER BY "ADDRESS_TYPE";