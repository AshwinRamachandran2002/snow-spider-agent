WITH tx AS (   -- successful external transactions on 14-Oct-2016 (UTC)
    SELECT
        "from_address",
        "to_address",
        "value",
        ("gas_price" * "receipt_gas_used") AS "fee",
        "block_number"
    FROM   CRYPTO.CRYPTO_ETHEREUM_CLASSIC."TRANSACTIONS"
    WHERE  "receipt_status" = 1
      AND  "block_timestamp" >= 1476403200000000    -- 2016-10-14 00:00:00 UTC
      AND  "block_timestamp" <  1476489600000000    -- 2016-10-15 00:00:00 UTC
),
blk AS (        -- miner address per block
    SELECT "number",
           "miner"
    FROM   CRYPTO.CRYPTO_ETHEREUM_CLASSIC."BLOCKS"
),
deltas AS (     -- all balance-changing components
    SELECT "to_address"            AS "address",  "value"  AS "delta" FROM tx
    UNION ALL
    SELECT "from_address"          AS "address", - "value" AS "delta" FROM tx
    UNION ALL
    SELECT "from_address"          AS "address", - "fee"   AS "delta" FROM tx
    UNION ALL                      -- fees credited to miner
    SELECT COALESCE(blk."miner",'0x00') AS "address",
           tx."fee"                AS "delta"
    FROM   tx
    LEFT  JOIN blk
           ON tx."block_number" = blk."number"
),
net AS (        -- net change per address
    SELECT "address",
           SUM("delta") AS "net_change"
    FROM   deltas
    GROUP  BY "address"
)
SELECT
    MAX("net_change") AS "max_positive_change",
    MIN("net_change") AS "max_negative_change"
FROM   net;