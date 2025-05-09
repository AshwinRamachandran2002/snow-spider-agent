WITH "TRANSFERS" AS (
    SELECT 
        LOWER("from_address") AS "FROM_ADDR",
        LOWER("to_address")   AS "TO_ADDR",
        TO_DECIMAL("value")   AS "VAL"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
), 
"ADDR_MOVES" AS (
    -- Incoming amounts
    SELECT "TO_ADDR"  AS "ADDR",
           "VAL"      AS "IN_VAL",
           0          AS "OUT_VAL"
    FROM "TRANSFERS"
    UNION ALL
    -- Outgoing amounts
    SELECT "FROM_ADDR" AS "ADDR",
           0           AS "IN_VAL",
           "VAL"       AS "OUT_VAL"
    FROM "TRANSFERS"
), 
"BALANCES" AS (
    SELECT 
        "ADDR",
        SUM("IN_VAL") - SUM("OUT_VAL") AS "BALANCE"
    FROM "ADDR_MOVES"
    GROUP BY "ADDR"
)
SELECT 
    "ADDR"                       AS "ethereum_address",
    "BALANCE"
FROM "BALANCES"
WHERE "BALANCE" > 0
ORDER BY "BALANCE" ASC NULLS LAST
LIMIT 3;