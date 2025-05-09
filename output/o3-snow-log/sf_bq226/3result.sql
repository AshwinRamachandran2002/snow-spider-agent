WITH valid_transfers AS (
    SELECT
        LOWER(TRY_PARSE_JSON("ARGS")[0]::STRING) AS "from_address",
        TRY_PARSE_JSON("ARGS")[1]::STRING        AS "to_address"
    FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."DECODED_EVENTS"
    WHERE "EVENT_SIGNATURE" = 'Transfer(address,address,uint256)'
      -- after 2023-01-01 (timestamps are stored in µs)
      AND "BLOCK_TIMESTAMP" >= 1672444800000000
      -- `to_address` must be present and not the zero-address
      AND TRY_PARSE_JSON("ARGS")[1] IS NOT NULL
      AND TRY_PARSE_JSON("ARGS")[1]::STRING <> '0x0000000000000000000000000000000000000000'
      -- keep only events that came from blocks “larger than 4096 bytes” (approximate by block number > 4096)
      AND "BLOCK_NUMBER" > 4096
)
SELECT
    CONCAT('https://cronoscan.com/address/', "from_address") AS "sender_url",
    COUNT(*)                                                AS "transfer_cnt"
FROM valid_transfers
GROUP BY "from_address"
ORDER BY "transfer_cnt" DESC NULLS LAST
LIMIT 1;