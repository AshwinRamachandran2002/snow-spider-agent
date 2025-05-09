/*  Most-frequent sender (to non-zero receivers) since 2023-01-01
    inside blocks whose total log-data size exceeds 4 096 bytes        */
WITH big_blocks AS (                 -- blocks larger than 4 096 bytes
    SELECT
        l."block_number"
    FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS" l
    WHERE l."block_timestamp" >= 1672531200000000                     -- 2023-01-01 (µs)
    GROUP BY l."block_number"
    HAVING SUM( (LENGTH(l."data") - 2) / 2 ) > 4096                  -- bytes in block
), transfer_logs AS (            -- raw Transfer logs in those blocks
    SELECT
        LOWER(CONCAT('0x', RIGHT(l."topics"[1]::STRING, 40))) AS "from_address"
    FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS" l
    JOIN big_blocks b  ON l."block_number" = b."block_number"
    WHERE l."block_timestamp" >= 1672531200000000
      AND l."topics"[0]::STRING = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'  -- Transfer hash
      AND l."topics"[2] IS NOT NULL
      AND RIGHT(l."topics"[2]::STRING, 40) <> '0000000000000000000000000000000000000000'                 -- non-zero “to”
)
SELECT
    CONCAT('https://cronoscan.com/address/', "from_address") AS "sender_url",
    COUNT(*)                                                 AS "transfer_count"
FROM transfer_logs
GROUP BY "from_address"
ORDER BY "transfer_count" DESC NULLS LAST
LIMIT 1;