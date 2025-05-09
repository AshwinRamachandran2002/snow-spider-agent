WITH bnb_tokens AS (
    SELECT "address"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKENS
    WHERE "symbol" ILIKE '%BNB%'
),
received AS (
    SELECT
        "to_address"                                  AS addr,
        SUM(TRY_TO_DECIMAL("value"))                  AS received_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE "token_address" IN (SELECT "address" FROM bnb_tokens)
      AND "to_address" IS NOT NULL
      AND "to_address" ILIKE '0x%'                 -- normal addresses
      AND "to_address" NOT ILIKE '0x000%'          -- exclude zero address
    GROUP BY "to_address"
),
sent AS (
    SELECT
        "from_address"                                AS addr,
        SUM(TRY_TO_DECIMAL("value"))                  AS sent_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE "token_address" IN (SELECT "address" FROM bnb_tokens)
      AND "from_address" IS NOT NULL
      AND "from_address" ILIKE '0x%'               -- normal addresses
      AND "from_address" NOT ILIKE '0x000%'        -- exclude zero address
    GROUP BY "from_address"
),
balances AS (
    SELECT
        COALESCE(r.addr, s.addr)                     AS addr,
        COALESCE(r.received_wei, 0) - COALESCE(s.sent_wei, 0) AS net_wei
    FROM received r
    FULL JOIN sent s
      ON r.addr = s.addr
)
SELECT 
    SUM(net_wei) / 1e18 AS "circulating_supply_bnb"
FROM balances
WHERE net_wei > 0;