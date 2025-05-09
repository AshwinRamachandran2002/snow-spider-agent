/*  Max- & Min-final balances per address-type for Bitcoin Cash
    Period : 2014-03-01 00:00 UTC  →  2014-04-01 00:00 UTC          */

WITH credits AS (   -- all transaction OUTPUTS  =>  positive (credit)
    SELECT
        "type"                                        AS "address_type",
        VALUE::VARIANT:"0"::STRING                    AS "address",      -- first address in array
        SUM("value")                                  AS "credit"
    FROM "CRYPTO"."CRYPTO_BITCOIN_CASH"."OUTPUTS",
         LATERAL FLATTEN( INPUT => "addresses")
    WHERE "block_timestamp" >= 1393632000000000     -- 2014-03-01
      AND "block_timestamp" <  1396310400000000     -- 2014-04-01
    GROUP BY 1,2
),
debits AS (    -- all transaction INPUTS  =>  negative (debit)
    SELECT
        "type"                                        AS "address_type",
        VALUE::VARIANT:"0"::STRING                    AS "address",
        SUM("value")                                  AS "debit"
    FROM "CRYPTO"."CRYPTO_BITCOIN_CASH"."INPUTS",
         LATERAL FLATTEN( INPUT => "addresses")
    WHERE "block_timestamp" >= 1393632000000000
      AND "block_timestamp" <  1396310400000000
    GROUP BY 1,2
),
balances AS (  -- double-entry:  final_balance = credit – debit  per address
    SELECT
        COALESCE(c."address_type", d."address_type")                       AS "address_type",
        COALESCE(c."address",      d."address")                            AS "address",
        COALESCE(c."credit",0) - COALESCE(d."debit",0)                     AS "final_balance"
    FROM credits c
    FULL JOIN debits  d  ON c."address" = d."address"
)
SELECT
    "address_type",
    MAX("final_balance")  AS "max_final_balance",
    MIN("final_balance")  AS "min_final_balance"
FROM balances
GROUP BY "address_type"
ORDER BY "address_type";