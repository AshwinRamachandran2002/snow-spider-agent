WITH token_flows AS (
    /* incoming transfers (+) */
    SELECT
        "to_address"   AS "address",
        TRY_TO_NUMBER("value") AS amount
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    
    UNION ALL
    
    /* outgoing transfers (–) */
    SELECT
        "from_address" AS "address",
        -TRY_TO_NUMBER("value") AS amount
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
),
balances AS (
    SELECT
        "address",
        SUM(amount) AS net_balance
    FROM token_flows
    GROUP BY "address"
    HAVING SUM(amount) > 0           -- keep only positive holders
)
SELECT
    "address"                                            AS ethereum_address,
    TO_DECIMAL(net_balance, 38, 4)                       AS token_balance
FROM balances
ORDER BY net_balance ASC, ethereum_address ASC
LIMIT 3;