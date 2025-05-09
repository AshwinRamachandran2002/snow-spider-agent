WITH
-- all Bitcoin Cash outputs in March‑2014 (credits)
"period_outputs" AS (
    SELECT
        o."type"                                    AS "address_type",
        f.value::STRING                             AS "address",
        CAST(o."value" AS FLOAT)                    AS "amount"       -- credit
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS" o
         ,LATERAL FLATTEN(input => o."addresses") f
    WHERE TO_TIMESTAMP_NTZ(o."block_timestamp" / 1000000)
              BETWEEN '2014-03-01'::DATE AND '2014-03-31 23:59:59'::TIMESTAMP_NTZ
),
-- all Bitcoin Cash inputs in March‑2014 (debits → negative)
"period_inputs" AS (
    SELECT
        i."type"                                    AS "address_type",
        f.value::STRING                             AS "address",
        -CAST(i."value" AS FLOAT)                   AS "amount"       -- debit
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"  i
         ,LATERAL FLATTEN(input => i."addresses") f
    WHERE TO_TIMESTAMP_NTZ(i."block_timestamp" / 1000000)
              BETWEEN '2014-03-01'::DATE AND '2014-03-31 23:59:59'::TIMESTAMP_NTZ
),
-- combine debits and credits
"movements" AS (
    SELECT * FROM "period_outputs"
    UNION ALL
    SELECT * FROM "period_inputs"
),
-- net balance per address across the month
"balances" AS (
    SELECT
        "address_type",
        "address",
        SUM("amount") AS "final_balance"
    FROM "movements"
    GROUP BY "address_type","address"
)
-- maximum & minimum final balances per address type
SELECT
    "address_type",
    MAX("final_balance") AS "max_final_balance",
    MIN("final_balance") AS "min_final_balance"
FROM "balances"
GROUP BY "address_type"
ORDER BY "address_type";