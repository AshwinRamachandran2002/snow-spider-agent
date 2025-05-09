WITH big_blocks AS (   -- blocks whose decoded-event payload (ARGS text) exceeds 4 096 characters
    SELECT 
        "BLOCK_NUMBER"
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.DECODED_EVENTS
    WHERE "BLOCK_TIMESTAMP" >= 1672531200000000                 -- since 2023-01-01 UTC
    GROUP BY "BLOCK_NUMBER"
    HAVING SUM(COALESCE(LENGTH("ARGS"),0)) > 4096               -- “large” blocks
)

SELECT
    'https://cronoscan.com/address/' || PARSE_JSON("ARGS")[0]::STRING AS "cronoscan_url",
    COUNT(*)                                                      AS "transfer_count"
FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.DECODED_EVENTS
WHERE "EVENT_HASH"      = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'  -- Transfer
  AND "BLOCK_TIMESTAMP" >= 1672531200000000                          -- since 2023-01-01 UTC
  AND PARSE_JSON("ARGS")[1] IS NOT NULL                              -- non-null `to_address`
  AND "BLOCK_NUMBER" IN (SELECT "BLOCK_NUMBER" FROM big_blocks)      -- only large blocks
GROUP BY "cronoscan_url"
ORDER BY "transfer_count" DESC NULLS LAST
LIMIT 1;