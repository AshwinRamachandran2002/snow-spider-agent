WITH "transfers" AS (
    /* outgoing tokens (negative) */
    SELECT
        "from_address" AS "address",
        -TRY_TO_DECIMAL("value") AS "amount"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'

    UNION ALL

    /* incoming tokens (positive) */
    SELECT
        "to_address"   AS "address",
        TRY_TO_DECIMAL("value") AS "amount"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
),
"balances" AS (
    SELECT
        "address",
        SUM("amount") AS "balance"
    FROM "transfers"
    GROUP BY "address"
)
SELECT
    "address",
    "balance"
FROM "balances"
WHERE "balance" > 0
ORDER BY "balance" ASC NULLS LAST
LIMIT 3;