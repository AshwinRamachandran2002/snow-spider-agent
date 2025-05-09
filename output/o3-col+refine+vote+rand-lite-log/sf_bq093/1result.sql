WITH filtered_tx AS (            -- all successful txs on 14-Oct-2016 (UTC)
    SELECT 
        "hash",
        "from_address",
        "to_address",
        "value",
        "gas_price",
        "receipt_gas_used",
        ("gas_price" * "receipt_gas_used")      AS "gas_fee",
        "block_number"
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC."TRANSACTIONS"
    WHERE "receipt_status" = 1
      AND "block_timestamp" >= 1476403200000000   -- 2016-10-14 00:00:00 UTC
      AND "block_timestamp" <  1476489600000000   -- 2016-10-15 00:00:00 UTC
),
tx_miner AS (                     -- attach the miner that receives the gas fee
    SELECT 
        t.*,
        b."miner" AS "miner_address"
    FROM filtered_tx t
    LEFT JOIN CRYPTO.CRYPTO_ETHEREUM_CLASSIC."BLOCKS" b
           ON t."block_number" = b."number"
),
deltas AS (                       -- per-transaction balance impacts
    -- sender: pays value and gas
    SELECT 
        "from_address"           AS "address",
        - "value" - "gas_fee"    AS "delta"
    FROM tx_miner
    
    UNION ALL
    
    -- receiver: gets the transferred value
    SELECT 
        "to_address"             AS "address",
        "value"                  AS "delta"
    FROM tx_miner
    WHERE "to_address" IS NOT NULL
    
    UNION ALL
    
    -- miner: receives the gas fee
    SELECT 
        "miner_address"          AS "address",
        "gas_fee"                AS "delta"
    FROM tx_miner
    WHERE "miner_address" IS NOT NULL
),
addr_net AS (                     -- net change per address
    SELECT 
        "address",
        SUM("delta") AS "net_change"
    FROM deltas
    GROUP BY "address"
)
SELECT 
    MAX("net_change") AS "max_net_change",
    MIN("net_change") AS "min_net_change"
FROM addr_net;