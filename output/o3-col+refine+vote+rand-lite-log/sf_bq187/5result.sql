WITH bnb_tokens AS (   -- all contracts whose symbol contains “BNB”
    SELECT DISTINCT "address"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKENS"
    WHERE "symbol" ILIKE '%bnb%'
),

received AS (          -- total BNB received by each non-zero address
    SELECT
        "to_address"                             AS "address",
        SUM(TRY_CAST("value" AS NUMBER))         AS "received_raw"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS"
    WHERE "token_address" IN (SELECT "address" FROM bnb_tokens)
      AND "to_address" NOT ILIKE '0x000%'        -- exclude zero address
    GROUP BY "to_address"
),

sent AS (              -- total BNB sent by each non-zero address
    SELECT
        "from_address"                           AS "address",
        SUM(TRY_CAST("value" AS NUMBER))         AS "sent_raw"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS"
    WHERE "token_address" IN (SELECT "address" FROM bnb_tokens)
      AND "from_address" NOT ILIKE '0x000%'      -- exclude zero address
    GROUP BY "from_address"
),

balances AS (          -- net balance per address (received – sent)
    SELECT
        COALESCE(received."address", sent."address")                  AS "address",
        COALESCE(received."received_raw", 0) 
      - COALESCE(sent."sent_raw",     0)                              AS "balance_raw"
    FROM received
    FULL JOIN sent USING ("address")
    WHERE COALESCE(received."received_raw", 0) 
      - COALESCE(sent."sent_raw",     0) <> 0                         -- keep non-zero balances
)

SELECT 
    SUM("balance_raw") / POWER(10, 18)       AS "bnb_circulating_supply"
FROM balances;