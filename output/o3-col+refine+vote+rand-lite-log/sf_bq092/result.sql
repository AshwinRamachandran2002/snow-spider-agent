/*  Highest-positive and lowest-negative Dash balances for April-2023  */
WITH april_blocks AS (    -- all Dash blocks in April-2023
    SELECT  "number"  AS "block_number"
    FROM    CRYPTO.CRYPTO_DASH.BLOCKS
    WHERE   "timestamp_month" = '2023-04-01'
),
credits AS (              -- outputs = credits (positive)
    SELECT  ARRAY_TO_STRING("addresses", ',')      AS "address",
            "type",
            SUM("value")                          AS "amount"
    FROM    CRYPTO.CRYPTO_DASH.OUTPUTS  o
    JOIN    april_blocks                   b
           ON o."block_number" = b."block_number"
    GROUP BY 1,2
),
debits AS (               -- inputs = debits (negative)
    SELECT  ARRAY_TO_STRING("addresses", ',')      AS "address",
            "type",
           -SUM("value")                          AS "amount"
    FROM    CRYPTO.CRYPTO_DASH.INPUTS   i
    JOIN    april_blocks                   b
           ON i."block_number" = b."block_number"
    GROUP BY 1,2
),
ledger AS (               -- double-entry ledger
    SELECT * FROM credits
    UNION ALL
    SELECT * FROM debits
),
balances AS (             -- net balance per address & type
    SELECT  "address",
            "type",
            SUM("amount") AS "balance"
    FROM    ledger
    GROUP BY 1,2
)
SELECT  "address",
        "type",
        "balance"
FROM    balances
WHERE   "balance" = (SELECT MAX("balance") FROM balances)
   OR   "balance" = (SELECT MIN("balance") FROM balances)
ORDER BY "balance" DESC NULLS LAST;