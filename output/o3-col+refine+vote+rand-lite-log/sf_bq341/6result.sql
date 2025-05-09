-- top-3 smallest positive holders of the specified ERC-20 token
WITH sent AS (                     -- total tokens each address has SENT
    SELECT
        "from_address"                  AS addr,
        SUM(TO_DECIMAL("value"))        AS sent_val
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "from_address"
),
received AS (                  -- total tokens each address has RECEIVED
    SELECT
        "to_address"                    AS addr,
        SUM(TO_DECIMAL("value"))        AS recv_val
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "to_address"
)
SELECT
    COALESCE(r.addr, s.addr)                            AS "ethereum_address",
    (COALESCE(recv_val, 0) - COALESCE(sent_val, 0))     AS "balance"
FROM received r
FULL OUTER JOIN sent s
ON r.addr = s.addr
WHERE (COALESCE(recv_val, 0) - COALESCE(sent_val, 0)) > 0   -- keep only positive balances
ORDER BY "balance" ASC                                      -- smallest positive balances first
LIMIT 3;