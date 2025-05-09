WITH bnb_token AS (
    /* find the ERC-20 contract address of BNB on Ethereum */
    SELECT DISTINCT LOWER("address") AS "token_address"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKENS
    WHERE LOWER("symbol") = 'bnb'
),
bnb_transfers AS (
    /* all BNB transfers that do NOT involve the zero address */
    SELECT
        LOWER("from_address") AS "from_addr",
        LOWER("to_address")   AS "to_addr",
        TRY_CAST("value" AS DECIMAL(38,0)) AS "amount"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS t
    JOIN bnb_token b
      ON LOWER(t."token_address") = b."token_address"
    WHERE LOWER("from_address") <> '0x0000000000000000000000000000000000000000'
      AND LOWER("to_address")   <> '0x0000000000000000000000000000000000000000'
      AND "value" IS NOT NULL
),
received AS (      /* total BNB received by each address */
    SELECT "to_addr" AS "addr",
           SUM("amount") AS "received"
    FROM bnb_transfers
    GROUP BY "to_addr"
),
sent AS (           /* total BNB sent by each address */
    SELECT "from_addr" AS "addr",
           SUM("amount") AS "sent"
    FROM bnb_transfers
    GROUP BY "from_addr"
),
balances AS (       /* current balance = received − sent  */
    SELECT
        COALESCE(r."addr", s."addr")                        AS "addr",
        COALESCE(r."received", 0) - COALESCE(s."sent", 0)   AS "balance"
    FROM received r
    FULL OUTER JOIN sent s
        ON r."addr" = s."addr"
)
SELECT
    SUM("balance") / 1e18 AS "circulating_supply_bnb"
FROM balances
WHERE "balance" <> 0          -- keep only non-zero balances
  AND "addr" <> '0x0000000000000000000000000000000000000000';