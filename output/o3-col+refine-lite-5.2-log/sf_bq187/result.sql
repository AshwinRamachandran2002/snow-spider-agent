WITH "bnb_tokens" AS (   -- all ERC‑20 contracts whose symbol contains ‘BNB’
    SELECT "address" AS "token_address"
    FROM   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKENS"
    WHERE  "symbol" ILIKE '%BNB%'
),

/* total BNB received by every non‑zero address */
"received" AS (
    SELECT  tt."to_address"                       AS "address",
            SUM(CAST(tt."value" AS NUMBER(38,0))) AS "received_wei"
    FROM    "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS" tt
    JOIN    "bnb_tokens"  bt
           ON tt."token_address" = bt."token_address"
    WHERE   tt."to_address" NOT ILIKE '0x0000000000000000000000000000000000000000'
    GROUP BY tt."to_address"
),

/* total BNB sent by every non‑zero address */
"sent" AS (
    SELECT  tt."from_address"                     AS "address",
            SUM(CAST(tt."value" AS NUMBER(38,0))) AS "sent_wei"
    FROM    "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS" tt
    JOIN    "bnb_tokens"  bt
           ON tt."token_address" = bt."token_address"
    WHERE   tt."from_address" NOT ILIKE '0x0000000000000000000000000000000000000000'
    GROUP BY tt."from_address"
),

/* net balance per address = received – sent */
"net_balances" AS (
    SELECT  COALESCE(r."address", s."address")                    AS "address",
            COALESCE(r."received_wei", 0) - COALESCE(s."sent_wei", 0) AS "balance_wei"
    FROM    "received" r
    FULL OUTER JOIN "sent" s
           ON r."address" = s."address"
)

/* circulating supply: sum of all positive balances, scaled to 18‑decimals */
SELECT  SUM("balance_wei") / 1e18  AS "total_circulating_supply_bnb"
FROM    "net_balances"
WHERE   "balance_wei" > 0;