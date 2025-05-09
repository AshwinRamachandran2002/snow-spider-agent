WITH "recv" AS (
    SELECT  "to_address"                         AS "address",
            SUM(TRY_TO_NUMBER("value"))         AS "recv"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE   "token_address" = '0xb8c77482e45f1f44de1745f52c74426c631bdd52'
      AND   "to_address"   <> '0x0000000000000000000000000000000000000000'
    GROUP BY "to_address"
),
"sent" AS (
    SELECT  "from_address"                       AS "address",
            SUM(TRY_TO_NUMBER("value"))         AS "sent"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE   "token_address" = '0xb8c77482e45f1f44de1745f52c74426c631bdd52'
      AND   "from_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "from_address"
),
"balances" AS (
    SELECT  COALESCE(r."address", s."address")                AS "address",
            COALESCE(r."recv", 0) - COALESCE(s."sent", 0)     AS "balance_raw"
    FROM    "recv" r
    FULL JOIN "sent" s
           ON r."address" = s."address"
    WHERE   COALESCE(r."recv", 0) - COALESCE(s."sent", 0) <> 0
)
SELECT  SUM("balance_raw") / 1e18  AS "circulating_supply_BNB"
FROM    "balances";