WITH "BNB_TOKEN" AS (
    SELECT DISTINCT LOWER("address") AS "token_address"
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKENS"
    WHERE UPPER("symbol") = 'BNB'
),
"TRANSFERS" AS (

    /* credit receivers (exclude zero‑address receivers) */
    SELECT
        LOWER("to_address")   AS "address",
        TRY_CAST("value" AS NUMBER(38,0))     AS "amount"
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS" TT
    JOIN "BNB_TOKEN" BT
      ON LOWER(TT."token_address") = BT."token_address"
    WHERE LOWER("to_address") <> '0x0000000000000000000000000000000000000000'

    UNION ALL

    /* debit senders (exclude zero‑address senders) */
    SELECT
        LOWER("from_address") AS "address",
        - TRY_CAST("value" AS NUMBER(38,0))    AS "amount"
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS" TT
    JOIN "BNB_TOKEN" BT
      ON LOWER(TT."token_address") = BT."token_address"
    WHERE LOWER("from_address") <> '0x0000000000000000000000000000000000000000'
),
"BALANCES" AS (
    SELECT
        "address",
        SUM("amount") AS "balance_wei"
    FROM "TRANSFERS"
    GROUP BY "address"
)

SELECT
    SUM("balance_wei") / POWER(10,18) AS "BNB_CIRCULATING_SUPPLY"
FROM "BALANCES";