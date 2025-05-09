WITH "BNB_TOKEN" AS (      -- get the ERC-20 contract address of BNB
    SELECT LOWER("address") AS "token_address"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKENS"
    WHERE UPPER("symbol") = 'BNB'
    ORDER BY "block_number"        -- choose the first (oldest) record if duplicates exist
    LIMIT 1
),
"TRANSFERS" AS (           -- all BNB transfers that do NOT involve the zero address
    SELECT
        LOWER(tt."from_address")               AS "from_addr",
        LOWER(tt."to_address")                 AS "to_addr",
        TRY_TO_DECIMAL(tt."value")             AS "value_wei"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
    JOIN "BNB_TOKEN" b
      ON LOWER(tt."token_address") = b."token_address"
    WHERE LOWER(tt."from_address") <> '0x0000000000000000000000000000000000000000'
      AND LOWER(tt."to_address")   <> '0x0000000000000000000000000000000000000000'
),
"BALANCES" AS (            -- net balance per address = received – sent
    SELECT
        "addr",
        SUM(CASE WHEN "direction" = 'in'
                 THEN "value_wei"
                 ELSE - "value_wei"
            END) AS "balance_wei"
    FROM (
        SELECT "to_addr"   AS "addr", "value_wei", 'in'  AS "direction" FROM "TRANSFERS"
        UNION ALL
        SELECT "from_addr" AS "addr", "value_wei", 'out' AS "direction" FROM "TRANSFERS"
    ) bal
    GROUP BY "addr"
    HAVING "balance_wei" <> 0          -- keep only addresses with a non-zero balance
)
SELECT
    SUM("balance_wei") / POWER(10,18)  AS "total_circulating_supply_bnb"
FROM "BALANCES";