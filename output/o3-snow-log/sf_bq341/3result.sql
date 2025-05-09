WITH transfers AS (
    /* incoming tokens */
    SELECT  LOWER("to_address")   AS address,
            TO_DECIMAL("value")   AS in_val,
            0                     AS out_val
    FROM    CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE   LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'

    UNION ALL

    /* outgoing tokens */
    SELECT  LOWER("from_address") AS address,
            0                     AS in_val,
            TO_DECIMAL("value")   AS out_val
    FROM    CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE   LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
),
balances AS (
    SELECT  address,
            SUM(in_val) - SUM(out_val) AS balance
    FROM    transfers
    GROUP BY address
)
SELECT  address,
        balance
FROM    balances
WHERE   balance > 0                -- keep only positive holders
ORDER BY balance ASC NULLS LAST     -- smallest positive balances first
LIMIT 3;                            -- top-3