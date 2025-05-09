WITH "bnb_tokens" AS (
    /* 1.  BNB token contract(s) deployed on Ethereum            */
    SELECT DISTINCT LOWER("address") AS "token_address"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKENS"
    WHERE  UPPER("symbol") = 'BNB'
),

"filtered_transfers" AS (
    /* 2.  All BNB transfers that do NOT involve the zero address */
    SELECT  LOWER("token_address")           AS "token_address",
            LOWER("from_address")            AS "from_address",
            LOWER("to_address")              AS "to_address",
            TRY_TO_DECIMAL("value")          AS "value_wei"          -- value in Wei‑like smallest unit
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS"
    WHERE   LOWER("token_address") IN (SELECT "token_address" FROM "bnb_tokens")
      AND   LOWER("from_address") <> '0x0000000000000000000000000000000000000000'
      AND   LOWER("to_address")   <> '0x0000000000000000000000000000000000000000'
),

"address_flows" AS (
    /* 3.  Split each transfer into an incoming and outgoing leg  */
    SELECT  "to_address"   AS "address",
            "value_wei"    AS "amount_signed"
    FROM    "filtered_transfers"

    UNION ALL

    SELECT  "from_address" AS "address",
           - "value_wei"   AS "amount_signed"
    FROM    "filtered_transfers"
),

"balances" AS (
    /* 4.  Net balance per non‑zero address                       */
    SELECT  "address",
            SUM("amount_signed") AS "balance_wei"
    FROM    "address_flows"
    GROUP  BY "address"
    HAVING  SUM("amount_signed") <> 0          -- keep only non‑zero balances
),

"total_circulating_supply" AS (
    /* 5.  Aggregate all positive balances and convert to 10^18   */
    SELECT  SUM("balance_wei") / 1e18    AS "circulating_supply"
    FROM    "balances"
)

SELECT  "circulating_supply"
FROM    "total_circulating_supply";