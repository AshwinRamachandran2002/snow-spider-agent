WITH credits AS (
    SELECT
        "to_address"                              AS ethereum_address,
        SUM(TRY_TO_NUMBER("value"))              AS total_in
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "to_address"
),
debits AS (
    SELECT
        "from_address"                            AS ethereum_address,
        SUM(TRY_TO_NUMBER("value"))              AS total_out
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "from_address"
),
balances AS (
    SELECT
        COALESCE(c.ethereum_address, d.ethereum_address)      AS ethereum_address,
        COALESCE(c.total_in, 0) - COALESCE(d.total_out, 0)     AS token_balance
    FROM credits c
    FULL OUTER JOIN debits d
        ON c.ethereum_address = d.ethereum_address
)
SELECT
    ethereum_address,
    TO_DECIMAL(token_balance, 38, 4) AS token_balance
FROM balances
WHERE token_balance > 0
ORDER BY token_balance ASC, ethereum_address
LIMIT 3;