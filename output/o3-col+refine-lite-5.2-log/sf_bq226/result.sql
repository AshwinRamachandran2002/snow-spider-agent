SELECT
  CONCAT('https://cronoscan.com/address/', LOWER("sender")) AS "sender_url"
FROM (
  SELECT
    PARSE_JSON("ARGS")[0]::STRING AS "sender",
    COUNT(*)                    AS "tx_count"
  FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."DECODED_EVENTS"
  WHERE "EVENT_SIGNATURE" = 'Transfer(address,address,uint256)'
    -- exclude zero‑address recipients
    AND PARSE_JSON("ARGS")[1]::STRING <> '0x0000000000000000000000000000000000000000'
    -- blocks since 2023‑01‑01 (microseconds)
    AND "BLOCK_TIMESTAMP" >= 1672531200000000
    -- only consider blocks numbered greater than 4096 (proxy for “larger than 4096 bytes”)
    AND "BLOCK_NUMBER" > 4096
  GROUP BY "sender"
  ORDER BY "tx_count" DESC NULLS LAST
  LIMIT 1
) AS top_sender;