WITH april_blocks AS (   -- all Dash blocks in April-2023
    SELECT  "hash"
    FROM    CRYPTO.CRYPTO_DASH.BLOCKS
    WHERE   "timestamp_month" = '2023-04-01'
),
movements AS (           -- credits ( + ) and debits ( – )
    /* 1) Outputs → credits */
    SELECT
        ARRAY_TO_STRING("addresses", ',')          AS "address",
        "type",
        SUM("value")                               AS "amount"
    FROM   CRYPTO.CRYPTO_DASH.OUTPUTS   o
    JOIN   april_blocks                b
           ON o."block_hash" = b."hash"
    GROUP  BY 1,2

    UNION ALL

    /* 2) Inputs → debits (negative sign) */
    SELECT
        ARRAY_TO_STRING("addresses", ',')          AS "address",
        "type",
        -SUM("value")                              AS "amount"
    FROM   CRYPTO.CRYPTO_DASH.INPUTS    i
    JOIN   april_blocks                 b
           ON i."block_hash" = b."hash"
    GROUP  BY 1,2
),
balances AS (           -- net balance per (address,type)
    SELECT  "address",
            "type",
            SUM("amount")  AS "balance"
    FROM    movements
    GROUP   BY 1,2
)
SELECT  "address",
        "type",
        "balance"
FROM    balances
QUALIFY  "balance" = MAX("balance") OVER()   -- highest positive
     OR  "balance" = MIN("balance") OVER()   -- lowest (most negative)
ORDER BY "balance" DESC NULLS LAST;