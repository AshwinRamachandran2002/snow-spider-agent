WITH incoming AS (
    SELECT
        "to_address"     AS "address",
        SUM(TO_DECIMAL("value")) AS "amt_in"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "to_address"
),
outgoing AS (
    SELECT
        "from_address"   AS "address",
        SUM(TO_DECIMAL("value")) AS "amt_out"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "from_address"
),
balances AS (
    SELECT
        COALESCE(incoming."address", outgoing."address")        AS "ethereum_address",
        COALESCE(incoming."amt_in", 0) - COALESCE(outgoing."amt_out", 0) AS "net_token_balance"
    FROM incoming
    FULL JOIN outgoing
           ON incoming."address" = outgoing."address"
)
SELECT
    "ethereum_address",
    "net_token_balance"
FROM balances
WHERE "net_token_balance" > 0
ORDER BY "net_token_balance" ASC
LIMIT 3;