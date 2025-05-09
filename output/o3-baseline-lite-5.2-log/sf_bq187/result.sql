WITH "BNB_TOKEN" AS (   -- fetch BNB ERC‑20 contract address
    SELECT LOWER("address") AS "token_address"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKENS"
    WHERE UPPER("symbol") = 'BNB'
),

-- create one row for the receiver (+value) and one for the sender (‑value)
"TRANSFER_ROWS" AS (
    SELECT
        LOWER("to_address")   AS "address",
        TRY_TO_DECIMAL("value") AS "delta"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS"
    WHERE LOWER("token_address") IN (SELECT "token_address" FROM "BNB_TOKEN")

    UNION ALL

    SELECT
        LOWER("from_address") AS "address",
        -TRY_TO_DECIMAL("value") AS "delta"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS"
    WHERE LOWER("token_address") IN (SELECT "token_address" FROM "BNB_TOKEN")
),

-- aggregate net balance per address (in Wei) and exclude the zero address
"BALANCES" AS (
    SELECT
        "address",
        SUM("delta") AS "balance_wei"
    FROM "TRANSFER_ROWS"
    GROUP BY "address"
    HAVING "address" <> '0x0000000000000000000000000000000000000000'
)

-- total circulating supply in units (divide by 10^18)
SELECT
    SUM("balance_wei") / POW(10, 18) AS "TOTAL_CIRCULATING_SUPPLY_BNB"
FROM "BALANCES";