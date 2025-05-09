/*--------------------------------------------------------------
  Maximum & minimum final balances per Bitcoin Cash address type
  (inputs = debits, outputs = credits) for 2014-03-01–2014-04-01
----------------------------------------------------------------*/
WITH

-- 1.  Filter OUTPUT rows inside the period and keep amount as credit (+)
"outputs_201403" AS (
    SELECT
        o."addresses"           AS "addresses",
        o."type"                AS "address_type",
        o."value"::FLOAT        AS "amount"          -- credit
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS" o
    WHERE o."block_timestamp" >= 1393632000000000   -- 2014-03-01 00:00:00 UTC
      AND o."block_timestamp" <  1396310400000000   -- 2014-04-01 00:00:00 UTC
),

-- 2.  Filter INPUT rows inside the period and turn amount into debit (-)
"inputs_201403" AS (
    SELECT
        i."addresses"           AS "addresses",
        i."type"                AS "address_type",
       -i."value"::FLOAT        AS "amount"          -- debit
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"  i
    WHERE i."block_timestamp" >= 1393632000000000
      AND i."block_timestamp" <  1396310400000000
),

-- 3.  Union debits and credits, explode address arrays, and
--     calculate the final balance for every individual address
"address_balances" AS (
    SELECT
        addr.value::STRING                      AS "address",
        t."address_type",
        SUM(t."amount")                         AS "final_balance"
    FROM (
        SELECT * FROM "outputs_201403"
        UNION ALL
        SELECT * FROM "inputs_201403"
    ) t,
    LATERAL FLATTEN(input => t."addresses") AS addr
    GROUP BY addr.value::STRING, t."address_type"
)

-- 4.  For each address type, return maximum & minimum final balances
SELECT
    "address_type",
    MAX("final_balance")      AS "max_final_balance",
    MIN("final_balance")      AS "min_final_balance"
FROM "address_balances"
GROUP BY "address_type"
ORDER BY "address_type";