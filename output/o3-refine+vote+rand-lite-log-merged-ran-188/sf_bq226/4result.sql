SELECT 
       CONCAT('https://cronoscan.com/address/', PARSE_JSON("ARGS")[0]::STRING) AS "cronoscan_sender_url",
       COUNT(*)                                                              AS "tx_cnt"
FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."DECODED_EVENTS"
WHERE "EVENT_SIGNATURE"  = 'Transfer(address,address,uint256)'
  -- on–chain activity since 2023-01-01 (timestamp stored in micro-seconds)
  AND "BLOCK_TIMESTAMP"  >= 1672531200000000
  -- restrict to “blocks larger than 4096 bytes” (interpreted here as block numbers > 4096)
  AND "BLOCK_NUMBER"     > 4096
  -- keep only transfers with a non-null recipient
  AND PARSE_JSON("ARGS")[1] IS NOT NULL
GROUP BY "cronoscan_sender_url"
ORDER BY "tx_cnt" DESC NULLS LAST
LIMIT 1;