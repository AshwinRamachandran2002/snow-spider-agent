WITH transfers AS (
    /* incoming amounts */
    SELECT 
        "to_address"  AS address,
        TRY_TO_NUMBER("value")      AS amt
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'

    UNION ALL
    
    /* outgoing amounts (as negative) */
    SELECT 
        "from_address" AS address,
        -TRY_TO_NUMBER("value")     AS amt
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
)

SELECT
    address,
    SUM(amt) AS balance
FROM transfers
GROUP BY address
HAVING balance > 0                 -- only positive balances
ORDER BY balance ASC NULLS LAST    -- smallest positives first
LIMIT 3;