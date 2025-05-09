WITH tx_april AS (      -- April‑2023 Dash transactions
    SELECT "hash"
    FROM   "CRYPTO"."CRYPTO_DASH"."TRANSACTIONS"
    WHERE  "block_timestamp_month" = '2023-04-01'
),

/* outputs = credits (positive) */
credits AS (
    SELECT 
        ARRAY_TO_STRING("addresses", ',')     AS "dash_address",
        "type"                                AS "script_type",
        SUM("value")                          AS "amount"
    FROM   "CRYPTO"."CRYPTO_DASH"."OUTPUTS" o
    JOIN   tx_april                        t  ON o."transaction_hash" = t."hash"
    GROUP  BY 1,2
),

/* inputs = debits (negative) */
debits AS (
    SELECT 
        ARRAY_TO_STRING("addresses", ',')     AS "dash_address",
        "type"                                AS "script_type",
        -SUM("value")                         AS "amount"
    FROM   "CRYPTO"."CRYPTO_DASH"."INPUTS"  i
    JOIN   tx_april                        t  ON i."transaction_hash" = t."hash"
    GROUP  BY 1,2
),

/* net balance per address & script_type */
net AS (
    SELECT  "dash_address",
            "script_type",
            SUM("amount") AS "balance"
    FROM   (
        SELECT * FROM credits
        UNION ALL
        SELECT * FROM debits
    )
    GROUP BY "dash_address","script_type"
),

/* pick highest and lowest balances */
ranked AS (
    SELECT  "dash_address",
            "balance",
            RANK() OVER (ORDER BY "balance" DESC) AS r_high,
            RANK() OVER (ORDER BY "balance" ASC)  AS r_low
    FROM    net
)

SELECT  "dash_address",
        TO_DECIMAL("balance",38,9) AS "balance"
FROM    ranked
WHERE   r_high = 1
   OR   r_low  = 1
ORDER BY "balance" DESC;