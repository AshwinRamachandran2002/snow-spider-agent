/*  Sender (FROM_ADDRESS) that appears most often since 2023-01-01 UTC
    in non-null “to_address” Transfer events, restricted to blocks
    whose height is greater than 4 096 ( >≈ “larger than 4096 bytes” ).

    Returned as a full Cronoscan URL.                                              */
SELECT
  CONCAT('https://cronoscan.com/address/', "FROM_ADDR") AS "SENDER_CRONOSCAN_URL"
FROM (
  SELECT
    PARSE_JSON("ARGS")[0]::STRING AS "FROM_ADDR",
    COUNT(*)                     AS "TX_COUNT"
  FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."DECODED_EVENTS"
  WHERE "EVENT_SIGNATURE" = 'Transfer(address,address,uint256)'
    AND "BLOCK_TIMESTAMP" >= 1672531200000000      -- 2023-01-01 UTC (µs)
    AND PARSE_JSON("ARGS")[1]::STRING <> '0x0000000000000000000000000000000000000000'
    AND "BLOCK_NUMBER" > 4096                      -- blocks “larger than 4096 bytes”
  GROUP BY "FROM_ADDR"
  ORDER BY "TX_COUNT" DESC NULLS LAST
  LIMIT 1
);