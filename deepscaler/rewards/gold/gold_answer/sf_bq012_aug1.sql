-- Task: Calculate the net balance of each address based on incoming and outgoing transfers from the traces table (only successful transactions, excluding call types like delegatecall, callcode, and staticcall), excluding null addresses. Display the top 100 addresses with the highest balances.
SELECT
    "address",
    SUM("value") AS "balance"
FROM (
  -- Debits
  SELECT 
    "to_address" AS "address",
    "value" AS "value"
  FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
  WHERE "to_address" IS NOT NULL
    AND "status" = 1
    AND ("call_type" NOT IN ('delegatecall', 'callcode', 'staticcall') OR "call_type" IS NULL)
  
  UNION ALL
  
  -- Credits
  SELECT 
    "from_address" AS "address",
    - "value" AS "value"
  FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
  WHERE "from_address" IS NOT NULL
    AND "status" = 1
    AND ("call_type" NOT IN ('delegatecall', 'callcode', 'staticcall') OR "call_type" IS NULL)
) AS "double_entry_book"
GROUP BY "address"
ORDER BY "balance" DESC
LIMIT 100;