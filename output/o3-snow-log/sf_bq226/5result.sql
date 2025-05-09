/*  Most-frequent sender URL on Cronos
    – ERC-20 Transfer events
    – to_address not NULL / not zero-address
    – blocks whose combined ARG string length > 4 096 bytes
    – since 1-Jan-2023                                              */

WITH blk_over_4k AS (      -- blocks that are “larger than 4096 bytes”
    SELECT
        "BLOCK_NUMBER",
        SUM(LENGTH("ARGS")) AS total_bytes
    FROM   "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."DECODED_EVENTS"
    WHERE  "BLOCK_TIMESTAMP" >= 1672531200000000
           AND "EVENT_SIGNATURE" = 'Transfer(address,address,uint256)'
           AND "ARGS" IS NOT NULL
    GROUP  BY "BLOCK_NUMBER"
    HAVING total_bytes > 4096
),
filtered_transfers AS (    -- keep only desired Transfer events
    SELECT
        PARSE_JSON(d."ARGS")[0]::STRING AS "from_address"
    FROM   "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."DECODED_EVENTS" d
           JOIN blk_over_4k b
             ON d."BLOCK_NUMBER" = b."BLOCK_NUMBER"
    WHERE  d."BLOCK_TIMESTAMP" >= 1672531200000000
           AND d."EVENT_SIGNATURE" = 'Transfer(address,address,uint256)'
           AND PARSE_JSON(d."ARGS")[1]::STRING IS NOT NULL
           AND PARSE_JSON(d."ARGS")[1]::STRING <> '0x0000000000000000000000000000000000000000'
)
SELECT
    'https://cronoscan.com/address/' || "from_address"  AS "most_frequent_sender_url"
FROM   filtered_transfers
GROUP  BY 1
ORDER  BY COUNT(*) DESC NULLS LAST
LIMIT  1;