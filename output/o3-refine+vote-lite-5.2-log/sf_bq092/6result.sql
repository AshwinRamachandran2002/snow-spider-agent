WITH balances AS (
    /*  positive credits from outputs  */
    SELECT
        ARRAY_TO_STRING("addresses", ',')                    AS "address",
        CAST("value" AS FLOAT)                               AS "amt"
    FROM CRYPTO.CRYPTO_DASH.OUTPUTS
    WHERE DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ("block_timestamp"/1e6)) = '2023-04-01'

    UNION ALL
    
    /*  negative debits from inputs  */
    SELECT
        ARRAY_TO_STRING("addresses", ',')                    AS "address",
        -CAST("value" AS FLOAT)                              AS "amt"
    FROM CRYPTO.CRYPTO_DASH.INPUTS
    WHERE DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ("block_timestamp"/1e6)) = '2023-04-01'
),

address_balances AS (
    SELECT
        "address",
        SUM("amt") AS "balance"
    FROM balances
    GROUP BY "address"
)

SELECT
    /* highest balance */
    (SELECT "address"  FROM address_balances ORDER BY "balance" DESC NULLS LAST  LIMIT 1) AS "highest_balance_address",
    (SELECT "balance"  FROM address_balances ORDER BY "balance" DESC NULLS LAST  LIMIT 1) AS "highest_balance",
    
    /* lowest (most negative) balance */
    (SELECT "address"  FROM address_balances ORDER BY "balance" ASC  NULLS LAST  LIMIT 1) AS "lowest_balance_address",
    (SELECT "balance"  FROM address_balances ORDER BY "balance" ASC  NULLS LAST  LIMIT 1) AS "lowest_balance";