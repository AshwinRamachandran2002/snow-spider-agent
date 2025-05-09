WITH "movements" AS (
    /* incoming tokens add to balance */
    SELECT
        "to_address"   AS "address",
        CAST("value" AS NUMBER(38,0))          AS "amount"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'

    UNION ALL

    /* outgoing tokens subtract from balance */
    SELECT
        "from_address" AS "address",
        -CAST("value" AS NUMBER(38,0))         AS "amount"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
)

SELECT
    "address",
    SUM("amount") AS "net_balance"
FROM "movements"
GROUP BY "address"
HAVING SUM("amount") > 0                      -- keep only positive balances
ORDER BY
    "net_balance" ASC,                        -- smallest positive first
    "address"      ASC
LIMIT 3;                                      -- top‑3 smallest positive balances