WITH token_transfers AS (
    SELECT
        "from_address"      AS addr,
        -TO_DECIMAL("value") AS amount
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'

    UNION ALL

    SELECT
        "to_address"        AS addr,
        TO_DECIMAL("value") AS amount
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
),
balances AS (
    SELECT
        addr AS "ethereum_address",
        SUM(amount) AS balance
    FROM token_transfers
    GROUP BY addr
)
SELECT
    "ethereum_address"
FROM balances
WHERE balance > 0
ORDER BY balance ASC
LIMIT 3;