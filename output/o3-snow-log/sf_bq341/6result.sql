WITH "txs" AS (
    /* add received amount */
    SELECT
        LOWER("to_address")   AS "address",
        TO_DECIMAL("value")   AS "amount"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'

    UNION ALL

    /* subtract sent amount */
    SELECT
        LOWER("from_address") AS "address",
        - TO_DECIMAL("value") AS "amount"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
),
"balances" AS (
    SELECT
        "address",
        SUM("amount") AS "balance"
    FROM "txs"
    GROUP BY "address"
)
SELECT
    "address",
    "balance"
FROM "balances"
WHERE "balance" > 0
ORDER BY "balance" ASC NULLS LAST
LIMIT 3;