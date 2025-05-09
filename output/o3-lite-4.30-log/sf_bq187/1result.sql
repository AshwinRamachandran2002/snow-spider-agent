WITH "bnb_contract" AS (
    SELECT LOWER('0xb8c77482e45f1f44de1745f52c74426c631bdd52') AS "address"
    UNION
    SELECT LOWER("address")
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKENS"
    WHERE LOWER("symbol") = 'bnb'
),
"received" AS (
    SELECT LOWER("to_address")          AS "addr",
           SUM(TRY_TO_DECIMAL("value")) AS "recv_raw"
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS"
    WHERE LOWER("token_address") IN (SELECT "address" FROM "bnb_contract")
      AND LOWER("to_address") <> '0x0000000000000000000000000000000000000000'
    GROUP BY LOWER("to_address")
),
"sent" AS (
    SELECT LOWER("from_address")        AS "addr",
           SUM(TRY_TO_DECIMAL("value")) AS "sent_raw"
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS"
    WHERE LOWER("token_address") IN (SELECT "address" FROM "bnb_contract")
      AND LOWER("from_address") <> '0x0000000000000000000000000000000000000000'
    GROUP BY LOWER("from_address")
),
"balances" AS (
    SELECT r."addr",
           COALESCE(r."recv_raw",0) - COALESCE(s."sent_raw",0) AS "bal_raw"
    FROM "received" r
    LEFT JOIN "sent" s ON r."addr" = s."addr"
    UNION
    SELECT s."addr",
           -s."sent_raw" AS "bal_raw"
    FROM "sent" s
    LEFT JOIN "received" r ON r."addr" = s."addr"
    WHERE r."addr" IS NULL
)
SELECT
    'BNB'                                              AS "token",
    TO_DECIMAL(SUM("bal_raw") / 1e18, 38, 4)           AS "circulating_supply"
FROM "balances"
WHERE "bal_raw" > 0;