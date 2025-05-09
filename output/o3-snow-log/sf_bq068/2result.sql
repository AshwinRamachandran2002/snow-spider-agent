/*------------------------------------------------------------
  Compute max / min final balances (credits – debits) per 
  Bitcoin-Cash address-type between 2014-03-01 and 2014-04-01
-------------------------------------------------------------*/
WITH

-- 1.  Credits  (transaction outputs)
"output_side" AS (
    SELECT
        -- amount is positive for credits
        o."value"::NUMBER                AS "amount",
        a.VALUE::STRING                  AS "address",
        o."type"                         AS "address_type"
    FROM  CRYPTO.CRYPTO_BITCOIN_CASH.OUTPUTS  o
          ,LATERAL FLATTEN(INPUT => o."addresses") a
    WHERE o."block_timestamp"
          BETWEEN 1393632000000000      -- 2014-03-01 00:00:00 UTC
              AND 1396310400000000      -- 2014-04-01 00:00:00 UTC (exclusive)
),

-- 2.  Debits  (transaction inputs – stored as negative)
"input_side"  AS (
    SELECT
        -- amount is negative for debits
        -1 * i."value"::NUMBER           AS "amount",
        a.VALUE::STRING                  AS "address",
        i."type"                         AS "address_type"
    FROM  CRYPTO.CRYPTO_BITCOIN_CASH.INPUTS  i
          ,LATERAL FLATTEN(INPUT => i."addresses") a
    WHERE i."block_timestamp"
          BETWEEN 1393632000000000
              AND 1396310400000000
),

-- 3.  All entry lines combined
"entry_lines" AS (
    SELECT * FROM "output_side"
    UNION ALL
    SELECT * FROM "input_side"
),

-- 4.  Final balance per address & address-type
"address_balances" AS (
    SELECT
        "address_type",
        "address",
        SUM("amount")  AS "balance"
    FROM   "entry_lines"
    GROUP  BY "address_type","address"
)

-- 5.  Max / Min balance per address-type
SELECT
    "address_type",
    MAX("balance") AS "max_final_balance",
    MIN("balance") AS "min_final_balance"
FROM   "address_balances"
GROUP  BY "address_type"
ORDER  BY "address_type";