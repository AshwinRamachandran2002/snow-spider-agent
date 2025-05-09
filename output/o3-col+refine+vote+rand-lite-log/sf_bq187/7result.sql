WITH tokens_bnb AS (
    SELECT DISTINCT
           LOWER("address") AS "token_address"
    FROM   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKENS"
    WHERE  "symbol" ILIKE '%bnb%'
),
received AS (
    SELECT
           LOWER(tt."to_address") AS "holder",
           SUM(TRY_TO_DECIMAL(tt."value") / 1e18) AS "received_bnb"
    FROM   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS" tt
    WHERE  LOWER(tt."token_address") IN (SELECT "token_address" FROM tokens_bnb)
      AND  LOWER(tt."from_address") <> '0x0000000000000000000000000000000000000000'
    GROUP BY LOWER(tt."to_address")
),
sent AS (
    SELECT
           LOWER(tt."from_address") AS "holder",
           SUM(TRY_TO_DECIMAL(tt."value") / 1e18) AS "sent_bnb"
    FROM   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS" tt
    WHERE  LOWER(tt."token_address") IN (SELECT "token_address" FROM tokens_bnb)
      AND  LOWER(tt."to_address") <> '0x0000000000000000000000000000000000000000'
    GROUP BY LOWER(tt."from_address")
),
balances AS (
    SELECT
           COALESCE(r."holder", s."holder")                          AS "holder",
           COALESCE(r."received_bnb", 0) - COALESCE(s."sent_bnb", 0) AS "current_balance_bnb"
    FROM   received r
    FULL JOIN sent s
           ON r."holder" = s."holder"
)
SELECT
       SUM("current_balance_bnb") AS "circulating_supply_bnb"
FROM   balances
WHERE  "current_balance_bnb" > 0;