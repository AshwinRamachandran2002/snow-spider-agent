-- Top 3 Ethereum addresses with the smallest positive net balance
WITH ins AS (
    SELECT
        "to_address"   AS "address",
        SUM(TRY_TO_NUMBER("value")) AS "in_value"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "to_address"
),
outs AS (
    SELECT
        "from_address" AS "address",
        SUM(TRY_TO_NUMBER("value")) AS "out_value"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "from_address"
),
balances AS (
    SELECT
        COALESCE(i."address", o."address")                                      AS "address",
        COALESCE(i."in_value", 0) - COALESCE(o."out_value", 0)                  AS "net_balance"
    FROM ins i
    FULL JOIN outs o
        ON i."address" = o."address"
)
SELECT
    "address",
    "net_balance"
FROM balances
WHERE "net_balance" > 0                         -- only positive balances
ORDER BY "net_balance" ASC NULLS LAST           -- smallest first
LIMIT 3;                                        -- top-3