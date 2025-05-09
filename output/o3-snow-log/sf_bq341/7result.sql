WITH "token_transfers" AS (
    SELECT
        "from_address",
        "to_address",
        TO_DECIMAL("value") AS "value_dec"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
),
"all_moves" AS (
    /* outgoing amounts are negative, incoming are positive */
    SELECT "from_address" AS "address", - "value_dec" AS "delta" FROM "token_transfers"
    UNION ALL
    SELECT "to_address"   AS "address",   "value_dec" AS "delta" FROM "token_transfers"
),
"balances" AS (
    SELECT
        "address",
        SUM("delta") AS "balance"
    FROM "all_moves"
    GROUP BY "address"
)
SELECT
    "address",
    "balance"
FROM "balances"
WHERE "balance" > 0
ORDER BY "balance" ASC NULLS LAST
LIMIT 3;