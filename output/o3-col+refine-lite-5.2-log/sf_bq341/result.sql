WITH incoming AS (
    SELECT 
        "to_address"      AS "address",
        SUM(TO_NUMBER("value")) AS "in_amt"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "to_address"
),
outgoing AS (
    SELECT 
        "from_address"    AS "address",
        SUM(TO_NUMBER("value")) AS "out_amt"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "from_address"
),
balances AS (
    SELECT 
        COALESCE(i."address", o."address")                            AS "address",
        COALESCE(i."in_amt", 0) - COALESCE(o."out_amt", 0)            AS "net_balance"
    FROM incoming i
    FULL OUTER JOIN outgoing o
        ON i."address" = o."address"
)
SELECT 
    "address",
    "net_balance"
FROM balances
WHERE "net_balance" > 0
ORDER BY "net_balance" ASC
LIMIT 3;