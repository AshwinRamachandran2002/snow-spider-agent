SELECT 
    addr  AS "address",
    balance
FROM (
    SELECT 
        addr,
        SUM(amount) AS balance
    FROM (
        /* incoming tokens */
        SELECT 
            "to_address"   AS addr,
            TO_NUMBER("value") AS amount
        FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
        WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
        
        UNION ALL
        
        /* outgoing tokens (negative) */
        SELECT 
            "from_address" AS addr,
            -TO_NUMBER("value") AS amount
        FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
        WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    )
    GROUP BY addr
)
WHERE balance > 0                       -- keep only positive balances
ORDER BY balance ASC NULLS LAST         -- smallest positive first
LIMIT 3;                                -- top-3 smallest positive balances