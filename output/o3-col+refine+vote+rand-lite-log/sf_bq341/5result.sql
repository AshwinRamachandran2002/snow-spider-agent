WITH transfers AS (
    SELECT
        "from_address",
        "to_address",
        TO_DECIMAL("value") AS "value"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
),
inflow AS (
    SELECT
        "to_address" AS "address",
        SUM("value") AS "inflow"
    FROM transfers
    GROUP BY "address"
),
outflow AS (
    SELECT
        "from_address" AS "address",
        SUM("value") AS "outflow"
    FROM transfers
    GROUP BY "address"
),
net AS (
    SELECT
        COALESCE(i."address", o."address") AS "address",
        COALESCE(i."inflow", 0) - COALESCE(o."outflow", 0) AS "net_balance"
    FROM inflow i
    FULL JOIN outflow o USING ("address")
)
SELECT
    "address",
    "net_balance"
FROM net
WHERE "net_balance" > 0
ORDER BY "net_balance" ASC
LIMIT 3;