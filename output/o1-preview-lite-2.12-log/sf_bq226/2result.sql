SELECT CONCAT('https://arbiscan.io/address/', sender."from_address") AS "Sender_URL", COUNT(*) AS "Transaction_Count"
FROM (
  SELECT 
    (PARSE_JSON(t."ARGS"))[0]::STRING AS "from_address",
    (PARSE_JSON(t."ARGS"))[1]::STRING AS "to_address",
    t."BLOCK_TIMESTAMP"
  FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."DECODED_EVENTS" t
  WHERE t."BLOCK_TIMESTAMP" >= 1672531200
    AND t."ARGS" IS NOT NULL
    AND t."REMOVED" = FALSE
) sender
WHERE sender."to_address" IS NOT NULL
GROUP BY sender."from_address"
ORDER BY "Transaction_Count" DESC NULLS LAST
LIMIT 1;