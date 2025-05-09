WITH bnb_transfers AS (   -- canonical BNB contract
    SELECT
        "from_address",
        "to_address",
        TRY_CAST("value" AS NUMBER) AS value_raw
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS"
    WHERE  "token_address" = '0xb8c77482e45f1f44de1745f52c74426c631bdd52'
      AND  "from_address" NOT ILIKE '0x000%'     -- exclude zero-address interactions
      AND  "to_address"   NOT ILIKE '0x000%'
),
received AS (            -- total BNB received by each address
    SELECT
        "to_address"                    AS addr,
        SUM(value_raw)                  AS received_raw
    FROM   bnb_transfers
    GROUP  BY "to_address"
),
sent AS (                 -- total BNB sent by each address
    SELECT
        "from_address"                  AS addr,
        SUM(value_raw)                  AS sent_raw
    FROM   bnb_transfers
    GROUP  BY "from_address"
),
balances AS (             -- net positive balances
    SELECT
        COALESCE(r.addr, s.addr)                            AS addr,
        COALESCE(r.received_raw, 0) - COALESCE(s.sent_raw, 0) AS balance_raw
    FROM   received r
    FULL OUTER JOIN sent s ON r.addr = s.addr
    WHERE  COALESCE(r.received_raw, 0) - COALESCE(s.sent_raw, 0) > 0
)
SELECT
    SUM(balance_raw) / POWER(10, 18) AS "circulating_supply_BNB"
FROM   balances;