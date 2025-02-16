-- Task: Calculate the average net balance (in quadrillions, i.e., divide balances by 1e15) of the top 10 Ethereum addresses ranked by net balance, where net balance is calculated by summing:
-- 1) Incoming transfers ('value') to addresses from successful transactions in "TRACES" where "to_address" is not null and "call_type" is not in ('delegatecall', 'callcode', 'staticcall') or is null.
-- 2) Outgoing transfers (negative 'value') from addresses in successful transactions in "TRACES" where "from_address" is not null and "call_type" is not in ('delegatecall', 'callcode', 'staticcall') or is null.
-- 3) Miner rewards: Sum of gas fees per block for each miner address, calculated as the sum over all transactions of "receipt_gas_used" multiplied by "gas_price" in "TRANSACTIONS", joined with "BLOCKS" on "block_number", grouped by "miner".
-- 4) Sender gas fee deductions: Negative sum of "receipt_gas_used" multiplied by "gas_price" for each "from_address" in "TRANSACTIONS".
-- Exclude null addresses from all calculations. Round the final average net balance to two decimal places.

WITH double_entry_book AS (
  -- Debits: Incoming transfers to addresses
  SELECT 
    "to_address" AS "address",
    "value" AS "value"
  FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
  WHERE "to_address" IS NOT NULL
    AND "status" = 1
    AND ("call_type" NOT IN ('delegatecall', 'callcode', 'staticcall') OR "call_type" IS NULL)
  
  UNION ALL
  
  -- Credits: Outgoing transfers from addresses
  SELECT 
    "from_address" AS "address",
    - "value" AS "value"
  FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
  WHERE "from_address" IS NOT NULL
    AND "status" = 1
    AND ("call_type" NOT IN ('delegatecall', 'callcode', 'staticcall') OR "call_type" IS NULL)
  
  UNION ALL
  
  -- Miner rewards: Gas fees collected by miners
  SELECT 
    "miner" AS "address",
    SUM(CAST("receipt_gas_used" AS NUMBER) * CAST("gas_price" AS NUMBER)) AS "value"
  FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRANSACTIONS" AS "transactions"
  JOIN "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."BLOCKS" AS "blocks"
    ON "blocks"."number" = "transactions"."block_number"
  GROUP BY "blocks"."miner"
  
  UNION ALL
  
  -- Sender gas fee deductions
  SELECT 
    "from_address" AS "address",
    -(CAST("receipt_gas_used" AS NUMBER) * CAST("gas_price" AS NUMBER)) AS "value"
  FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRANSACTIONS"
),
top_10_balances AS (
  SELECT
    "address",
    SUM("value") AS "balance"
  FROM double_entry_book
  GROUP BY "address"
  ORDER BY "balance" DESC
  LIMIT 10
)
SELECT 
    ROUND(AVG("balance") / 1e15, 2) AS "average_balance_trillion"
FROM top_10_balances;