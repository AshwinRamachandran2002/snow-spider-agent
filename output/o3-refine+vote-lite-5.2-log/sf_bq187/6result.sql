WITH "BNB_TOKEN" AS (
    SELECT LOWER("address") AS "token_address"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKENS"
    WHERE  UPPER("symbol") = 'BNB'
),
"TRANSFERS_BNB" AS (
    SELECT  LOWER(tt."to_address")   AS "addr",
            TRY_TO_DECIMAL(tt."value") AS "amount_wei"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
            JOIN "BNB_TOKEN" b
              ON LOWER(tt."token_address") = b."token_address"
    WHERE   LOWER(tt."to_address") <> '0x0000000000000000000000000000000000000000'

    UNION ALL

    SELECT  LOWER(tt."from_address") AS "addr",
           -TRY_TO_DECIMAL(tt."value") AS "amount_wei"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
            JOIN "BNB_TOKEN" b
              ON LOWER(tt."token_address") = b."token_address"
    WHERE   LOWER(tt."from_address") <> '0x0000000000000000000000000000000000000000'
),
"BALANCES" AS (
    SELECT "addr",
           SUM("amount_wei") AS "balance_wei"
    FROM   "TRANSFERS_BNB"
    GROUP  BY "addr"
    HAVING SUM("amount_wei") <> 0          -- keep non‑zero balances
)
SELECT SUM("balance_wei") / POWER(10,18) AS "BNB_CIRCULATING_SUPPLY"
FROM   "BALANCES";