WITH token_transfers AS (
    SELECT
        LOWER("from_address") AS "from_addr",
        LOWER("to_address")   AS "to_addr",
        TRY_TO_DECIMAL("value") AS "val"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
),   
balance_changes AS (
    -- positive change for receivers
    SELECT "to_addr"   AS "address",  "val"        AS "delta" FROM token_transfers
    UNION ALL
    -- negative change for senders
    SELECT "from_addr" AS "address", - "val"       AS "delta" FROM token_transfers
),  
address_balances AS (
    SELECT
        "address",
        SUM("delta") AS "balance"
    FROM balance_changes
    GROUP BY "address"
)
SELECT
    "address",
    "balance"
FROM address_balances
WHERE "balance" > 0
ORDER BY "balance" ASC, "address"
LIMIT 3;