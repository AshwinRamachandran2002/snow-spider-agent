WITH big_blocks AS (  -- blocks ≥ 4 096 bytes of log-data since 2023-01-01
    SELECT
        "block_number"
    FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS"
    WHERE "block_timestamp" >= 1672531200000000          -- 2023-01-01 in µs
    GROUP BY "block_number"
    HAVING SUM(LENGTH("data")) > 4096
),
transfer_logs AS (     -- ERC-20 Transfer logs inside those big blocks
    SELECT
        LOWER('0x' || RIGHT(l."topics"[1]::STRING, 40)) AS from_address
    FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS" l
    JOIN big_blocks bb
      ON l."block_number" = bb."block_number"
    WHERE l."topics"[0]::STRING = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
      AND l."topics"[2] IS NOT NULL                     -- non-null ‘to’ topic
      AND l."block_timestamp" >= 1672531200000000
)
SELECT
    CONCAT('https://cronoscan.com/address/', from_address) AS most_frequent_sender_url,
    COUNT(*)                                              AS tx_count
FROM transfer_logs
GROUP BY 1
ORDER BY tx_count DESC NULLS LAST
LIMIT 1;