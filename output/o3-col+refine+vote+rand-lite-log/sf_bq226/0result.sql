WITH "BIG_BLOCKS" AS (          -- blocks that contain at least one very-large payload log
    SELECT DISTINCT "block_number"
    FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS"
    WHERE "block_timestamp" >= 1672531200000000          -- since 1-Jan-2023
      AND LENGTH("data") > 4096                          -- payload longer than 4 096 hex chars
),
"TRANSFER_LOGS" AS (            -- raw ERC-20 Transfer logs that appear in those blocks
    SELECT
        LOWER(                                   -- standardise to lower-case
            CONCAT(
                '0x',
                RIGHT(                           -- last 40 hex chars = address
                    TRY_PARSE_JSON("topics")[1]::STRING,
                    40
                )
            )
        ) AS "sender"
    FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS"
    WHERE "block_number" IN (SELECT "block_number" FROM "BIG_BLOCKS")
      AND TRY_PARSE_JSON("topics")[0]::STRING = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef' -- Transfer
      AND TRY_PARSE_JSON("topics")[2]::STRING NOT IN (                      -- non-null “to” address
            '0x0000000000000000000000000000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000'
        )
)
SELECT CONCAT('https://cronoscan.com/address/', "sender") AS "cronoscan_url"
FROM (
    SELECT "sender",
           COUNT(*) AS "tx_count"
    FROM "TRANSFER_LOGS"
    GROUP BY "sender"
    ORDER BY "tx_count" DESC NULLS LAST
    LIMIT 1
);