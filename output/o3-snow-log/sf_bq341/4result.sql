WITH "token_movements" AS (

    /* outgoing amounts are negative */
    SELECT  LOWER("from_address")           AS "address",
            -TRY_TO_NUMBER("value")         AS "delta"
    FROM    CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE   LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'

    UNION ALL

    /* incoming amounts are positive */
    SELECT  LOWER("to_address")             AS "address",
            TRY_TO_NUMBER("value")          AS "delta"
    FROM    CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE   LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
)

SELECT  "address",
        SUM("delta") AS "balance"
FROM    "token_movements"
GROUP BY "address"
HAVING   SUM("delta") > 0                        -- keep only positive balances
ORDER BY "balance" ASC NULLS LAST                -- smallest positive balances first
LIMIT 3;                                         -- top-3