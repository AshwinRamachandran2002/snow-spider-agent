WITH "bnb_transfers" AS (
    SELECT
        LOWER("from_address") AS "from_addr",
        LOWER("to_address")   AS "to_addr",
        TRY_TO_DECIMAL("value") AS "value"
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS"
    WHERE LOWER("token_address") = '0xb8c77482e45f1f44de1745f52c74426c631bdd52'   -- BNB ERC‑20 contract
      AND LOWER("from_address") <> '0x0000000000000000000000000000000000000000'   -- exclude zero‑address sends
      AND LOWER("to_address")   <> '0x0000000000000000000000000000000000000000'   -- exclude zero‑address receives
),
"deltas" AS (
    -- outgoing value is negative, incoming value is positive
    SELECT "from_addr" AS "address", - "value" AS "delta" FROM "bnb_transfers"
    UNION ALL
    SELECT "to_addr"   AS "address",   "value" AS "delta" FROM "bnb_transfers"
),
"balances" AS (
    SELECT
        "address",
        SUM("delta") AS "balance"
    FROM "deltas"
    GROUP BY "address"
    HAVING SUM("delta") <> 0                 -- keep only non‑zero balances
)
SELECT
    SUM("balance") / 1e18 AS "circulating_supply_bnb"   -- convert Wei‑style units to 10^18 units
FROM "balances";