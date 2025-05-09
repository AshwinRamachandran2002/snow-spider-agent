WITH big_blocks AS (  -- blocks with at least 4 096 logs since 2023-01-01
    SELECT "block_number"
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS
    WHERE "block_timestamp" >= 1672531200000000
    GROUP BY "block_number"
    HAVING COUNT(*) >= 4096
),
transfer_logs AS (    -- ERC-20 Transfer logs inside those big blocks
    SELECT
        LOWER('0x' || RIGHT(PARSE_JSON(l."topics")[1]::STRING, 40)) AS "from_address",
        LOWER('0x' || RIGHT(PARSE_JSON(l."topics")[2]::STRING, 40)) AS "to_address"
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS l
    JOIN big_blocks b
      ON l."block_number" = b."block_number"
    WHERE l."block_timestamp" >= 1672531200000000
      AND PARSE_JSON(l."topics")[0]::STRING =
          '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'  -- Transfer event hash
)
SELECT
    'https://cronoscan.com/address/' || "from_address" AS "sender_url",
    COUNT(*)                                          AS "tx_count"
FROM transfer_logs
WHERE "to_address" <> '0x0000000000000000000000000000000000000000'
GROUP BY "sender_url"
ORDER BY "tx_count" DESC NULLS LAST
LIMIT 1;