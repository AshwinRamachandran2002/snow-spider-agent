WITH "TRANSFERS" AS (
    SELECT
        LOWER("from_address") AS "ADDR_FROM",
        LOWER("to_address")   AS "ADDR_TO",
        TO_DECIMAL("value", 38, 0) AS "VAL"
    FROM
        CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE
        LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
),
"BALANCE_CHANGES" AS (
    SELECT  "ADDR_FROM" AS "ADDR", - "VAL" AS "DELTA" FROM "TRANSFERS"
    UNION ALL
    SELECT  "ADDR_TO"   AS "ADDR",   "VAL" AS "DELTA" FROM "TRANSFERS"
),
"BALANCES" AS (
    SELECT
        "ADDR",
        SUM("DELTA") AS "BALANCE"
    FROM
        "BALANCE_CHANGES"
    GROUP BY
        "ADDR"
    HAVING
        SUM("DELTA") > 0
)
SELECT
    "ADDR"              AS "ETH_ADDRESS",
    "BALANCE"
FROM
    "BALANCES"
ORDER BY
    "BALANCE" ASC,
    "ETH_ADDRESS" ASC
LIMIT 3;