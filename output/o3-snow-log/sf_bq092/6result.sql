WITH tx AS (   -- Dash transactions in April-2023
    SELECT "hash"
    FROM   CRYPTO.CRYPTO_DASH.TRANSACTIONS
    WHERE  "block_timestamp_month" = '2023-04-01'
),

/* credits (+) from outputs */
outputs_agg AS (
    SELECT
        /* concatenate every array of addresses into one comma-separated string */
        CASE 
            WHEN TYPEOF("addresses") = 'ARRAY' 
                 THEN ARRAY_TO_STRING("addresses",',')
            ELSE "addresses"::STRING
        END                                AS address,
        "type",
        SUM("value"::NUMBER)               AS amount          -- positive
    FROM   CRYPTO.CRYPTO_DASH.OUTPUTS
    WHERE  "transaction_hash" IN (SELECT "hash" FROM tx)
    GROUP  BY
        CASE 
            WHEN TYPEOF("addresses") = 'ARRAY' 
                 THEN ARRAY_TO_STRING("addresses",',')
            ELSE "addresses"::STRING
        END ,
        "type"
),

/* debits (-) from inputs */
inputs_agg AS (
    SELECT
        CASE 
            WHEN TYPEOF("addresses") = 'ARRAY' 
                 THEN ARRAY_TO_STRING("addresses",',')
            ELSE "addresses"::STRING
        END                                AS address,
        "type",
        -SUM("value"::NUMBER)              AS amount          -- negative
    FROM   CRYPTO.CRYPTO_DASH.INPUTS
    WHERE  "transaction_hash" IN (SELECT "hash" FROM tx)
    GROUP  BY
        CASE 
            WHEN TYPEOF("addresses") = 'ARRAY' 
                 THEN ARRAY_TO_STRING("addresses",',')
            ELSE "addresses"::STRING
        END ,
        "type"
),

/* net balance per address & type */
balances AS (
    SELECT address,
           "type",
           SUM(amount) AS balance
    FROM  (
           SELECT * FROM outputs_agg
           UNION ALL
           SELECT * FROM inputs_agg
          )
    GROUP BY address, "type"
),

/* highest balance */
highest AS (
    SELECT address, "type", balance
    FROM   balances
    ORDER  BY balance DESC NULLS LAST
    LIMIT  1
),

/* lowest balance */
lowest AS (
    SELECT address, "type", balance
    FROM   balances
    ORDER  BY balance ASC NULLS LAST
    LIMIT  1
)

/* return both extremes */
SELECT * FROM highest
UNION ALL
SELECT * FROM lowest;