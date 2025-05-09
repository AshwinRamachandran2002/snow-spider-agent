WITH "bnb_tokens" AS (
    SELECT "address"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKENS"
    WHERE  "symbol" ILIKE '%BNB%' OR "name" ILIKE '%BNB%'
),
"received" AS (      -- total Wei received per address
    SELECT  tt."to_address"                                     AS "addr",
            SUM(TRY_TO_NUMBER(tt."value"))                      AS "recv_wei"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
    JOIN    "bnb_tokens" tk
            ON  tt."token_address" = tk."address"
    WHERE   tt."to_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY tt."to_address"
),
"sent" AS (           -- total Wei sent per address
    SELECT  tt."from_address"                                   AS "addr",
            SUM(TRY_TO_NUMBER(tt."value"))                      AS "sent_wei"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
    JOIN    "bnb_tokens" tk
            ON  tt."token_address" = tk."address"
    WHERE   tt."from_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY tt."from_address"
),
"balances" AS (       -- net balance = received – sent
    SELECT  COALESCE(r."addr", s."addr")                        AS "address",
            COALESCE(r."recv_wei", 0) - COALESCE(s."sent_wei", 0) AS "balance_wei"
    FROM    "received" r
    FULL JOIN "sent" s
           ON r."addr" = s."addr"
)
SELECT  SUM("balance_wei") / POWER(10, 18)                       AS "circulating_supply_BNB"
FROM    "balances"
WHERE   "balance_wei" <> 0;