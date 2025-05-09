WITH top_address AS (
  SELECT "from_address"
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS"
  WHERE
    "receipt_status" = 1
    AND "block_timestamp" < 1630454400000000
    AND "input" = '0x'
  GROUP BY "from_address"
  ORDER BY COUNT(*) DESC NULLS LAST
  LIMIT 1
),
incoming AS (
  SELECT "to_address", SUM("value") AS total_received
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS"
  WHERE
    "receipt_status" = 1
    AND "block_timestamp" < 1630454400000000
    AND "input" = '0x'
  GROUP BY "to_address"
),
outgoing AS (
  SELECT "from_address",
         SUM("value" + ("receipt_gas_used" * "receipt_effective_gas_price")) AS total_spent
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS"
  WHERE
    "receipt_status" = 1
    AND "block_timestamp" < 1630454400000000
    AND "input" = '0x'
  GROUP BY "from_address"
)
SELECT
  ROUND((COALESCE(incoming.total_received, 0) - COALESCE(outgoing.total_spent, 0)) / 1e18, 4) AS "Ether_balance"
FROM top_address
LEFT JOIN incoming ON top_address."from_address" = incoming."to_address"
LEFT JOIN outgoing ON top_address."from_address" = outgoing."from_address";