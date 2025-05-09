WITH recv AS (
    SELECT 
        "to_address"   AS "address",
        SUM(TRY_TO_DECIMAL("value")) AS "received"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "to_address"
), 
sent AS (
    SELECT 
        "from_address" AS "address",
        SUM(TRY_TO_DECIMAL("value")) AS "sent"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "from_address"
)
SELECT  
    COALESCE(recv."address", sent."address") AS "ethereum_address",
    COALESCE(recv."received", 0) - COALESCE(sent."sent", 0) AS "net_token_balance"
FROM recv
FULL OUTER JOIN sent USING ("address")
WHERE COALESCE(recv."received", 0) - COALESCE(sent."sent", 0) > 0
ORDER BY "net_token_balance" ASC
LIMIT 3;