WITH token_moves AS (
    /* incoming amounts */
    SELECT 
        LOWER("to_address")   AS "address",
        TRY_TO_DECIMAL("value")      AS "amount"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'

    UNION ALL

    /* outgoing amounts (negative) */
    SELECT 
        LOWER("from_address") AS "address",
        -TRY_TO_DECIMAL("value")     AS "amount"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
)

SELECT
    "address"                AS "ethereum_address",
    SUM("amount")            AS "balance"
FROM token_moves
GROUP BY "address"
HAVING SUM("amount") > 0                -- only positive balances
ORDER BY SUM("amount") ASC NULLS LAST   -- smallest positive balances first
LIMIT 3;