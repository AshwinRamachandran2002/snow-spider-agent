-- Sender address that appears most frequently (since 2023-01-01, block_number > 4096)
-- in transfers where the “to_address” is not NULL.  
-- Returned as a complete URL on cronoscan.
SELECT 
  CONCAT('https://cronoscan.com/address/', LOWER(sender_address)) AS "MOST_USED_SENDER_URL"
FROM (
  SELECT 
    PARSE_JSON("ARGS")[0]::STRING          AS sender_address,
    COUNT(*)                               AS use_count
  FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.DECODED_EVENTS
  WHERE "EVENT_SIGNATURE" = 'Transfer(address,address,uint256)'
    AND PARSE_JSON("ARGS")[1]::STRING IS NOT NULL               -- ensure to_address present
    AND "BLOCK_TIMESTAMP" >= 1672531200000000                   -- 2023-01-01 (µs)
    AND "BLOCK_NUMBER"    > 4096                                -- blocks “larger than 4096 bytes”
  GROUP BY sender_address
  ORDER BY use_count DESC NULLS LAST
  LIMIT 1
);