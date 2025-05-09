WITH sent AS (
    SELECT 
        "from_address"           AS "address",
        SUM(TRY_TO_NUMBER("value")) AS "sent"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "from_address"
),
received AS (
    SELECT 
        "to_address"             AS "address",
        SUM(TRY_TO_NUMBER("value")) AS "received"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "to_address"
),
balances AS (
    SELECT
        COALESCE(r."address", s."address")                              AS "address",
        COALESCE(r."received", 0) - COALESCE(s."sent", 0)               AS "net_balance"
    FROM received r
    FULL OUTER JOIN sent s
        ON r."address" = s."address"
)
SELECT 
    "address",
    "net_balance"
FROM balances
WHERE "net_balance" > 0
ORDER BY "net_balance" ASC
LIMIT 3;