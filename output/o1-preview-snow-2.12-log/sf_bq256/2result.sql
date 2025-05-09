WITH excluded_transactions AS (
  SELECT DISTINCT "transaction_hash"
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
  WHERE "call_type" IN ('delegatecall', 'callcode', 'staticcall')
    AND "block_timestamp" < 1630454400000000
),
top_address AS (
  SELECT "from_address" AS address
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS" t
  WHERE t."receipt_status" = 1
    AND t."block_timestamp" < 1630454400000000
    AND t."hash" NOT IN (SELECT "transaction_hash" FROM excluded_transactions)
  GROUP BY "from_address"
  ORDER BY COUNT(*) DESC NULLS LAST
  LIMIT 1
),
incoming AS (
  SELECT SUM("value") AS total_incoming
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS"
  WHERE "to_address" = (SELECT address FROM top_address)
    AND "block_timestamp" < 1630454400000000
),
outgoing AS (
  SELECT SUM("value") AS total_outgoing
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS"
  WHERE "from_address" = (SELECT address FROM top_address)
    AND "block_timestamp" < 1630454400000000
),
gas_fees AS (
  SELECT SUM("gas_price" * "receipt_gas_used") AS total_gas_fees
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS"
  WHERE "from_address" = (SELECT address FROM top_address)
    AND "block_timestamp" < 1630454400000000
),
miner_rewards AS (
  SELECT SUM(
    CASE
      WHEN "number" <= 4370000 THEN 5 * POWER(10,18)
      WHEN "number" <= 7280000 THEN 3 * POWER(10,18)
      ELSE 2 * POWER(10,18)
    END
  ) AS total_miner_rewards
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."BLOCKS"
  WHERE "miner" = (SELECT address FROM top_address)
    AND "timestamp" < 1630454400000000
)
SELECT
  (SELECT address FROM top_address) AS "Address",
  ROUND((
    COALESCE((SELECT total_incoming FROM incoming), 0) +
    COALESCE((SELECT total_miner_rewards FROM miner_rewards), 0) -
    COALESCE((SELECT total_outgoing FROM outgoing), 0) -
    COALESCE((SELECT total_gas_fees FROM gas_fees), 0)
  ) / POWER(10,18), 4) AS "Final_Ether_Balance"
;