WITH month_tx AS (                                                      -- all Dash txs in Apr‑2023
    SELECT "hash"
    FROM   "CRYPTO"."CRYPTO_DASH"."TRANSACTIONS"
    WHERE  "block_timestamp_month" = '2023-04-01'
),
/* credits = outputs (positive) */
credits AS (
    SELECT  ARRAY_TO_STRING("addresses", ',')        AS "address",
            "type",
            SUM("value")                             AS "amount"
    FROM    "CRYPTO"."CRYPTO_DASH"."OUTPUTS"
    WHERE   "transaction_hash" IN (SELECT "hash" FROM month_tx)
    GROUP BY ARRAY_TO_STRING("addresses", ','), "type"
),
/* debits = inputs (negative) */
debits AS (
    SELECT  ARRAY_TO_STRING("addresses", ',')        AS "address",
            "type",
            -SUM("value")                            AS "amount"     -- negate → debit
    FROM    "CRYPTO"."CRYPTO_DASH"."INPUTS"
    WHERE   "transaction_hash" IN (SELECT "hash" FROM month_tx)
    GROUP BY ARRAY_TO_STRING("addresses", ','), "type"
),
/* net balance per (address,type) */
balances AS (
    SELECT  "address",
            "type",
            SUM("amount")                            AS "balance"
    FROM   (SELECT * FROM credits
            UNION ALL
            SELECT * FROM debits)
    GROUP BY "address","type"
),
extremes AS (                                           -- compute highest / lowest balance
    SELECT  MAX("balance") AS max_balance,
            MIN("balance") AS min_balance
    FROM    balances
)
/* return the rows holding those extreme values */
SELECT  'HIGHEST' AS "extreme",
        b."address",
        b."type",
        b."balance"
FROM    balances b, extremes e
WHERE   b."balance" = e.max_balance

UNION ALL

SELECT  'LOWEST'  AS "extreme",
        b."address",
        b."type",
        b."balance"
FROM    balances b, extremes e
WHERE   b."balance" = e.min_balance;