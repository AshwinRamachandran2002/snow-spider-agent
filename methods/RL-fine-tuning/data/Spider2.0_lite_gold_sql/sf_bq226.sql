SELECT CONCAT('https://cronoscan.com/address/', LOWER(tx.from_address)) AS Sender_URL,
       COUNT(*) AS Transaction_Count
FROM (
  SELECT t."TRANSACTION_HASH",
         t."BLOCK_NUMBER",
         MAX(CASE WHEN f.index = 0 THEN f.value::STRING ELSE NULL END) AS from_address,
         MAX(CASE WHEN f.index = 1 THEN f.value::STRING ELSE NULL END) AS to_address
  FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."DECODED_EVENTS" t,
       LATERAL FLATTEN(input => PARSE_JSON(t."ARGS")) f
  WHERE t."BLOCK_TIMESTAMP" >= 1672531200000000
    AND t."ARGS" IS NOT NULL
    AND t."EVENT_SIGNATURE" = 'Transfer(address,address,uint256)'
  GROUP BY t."TRANSACTION_HASH", t."BLOCK_NUMBER"
) tx
WHERE tx.from_address IS NOT NULL AND tx.to_address IS NOT NULL
GROUP BY tx.from_address
ORDER BY Transaction_Count DESC NULLS LAST
LIMIT 1;