WITH received AS (
  SELECT "to_address" AS "address", SUM("value") AS "amount"
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS"
  WHERE "receipt_status" = 1
    AND "block_timestamp" < DATE_PART(EPOCH_SECOND, TO_TIMESTAMP_NTZ('2021-09-01', 'YYYY-MM-DD')) * 1e6
  GROUP BY "to_address"
  UNION ALL
  SELECT "to_address" AS "address", SUM("value") AS "amount"
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
  WHERE ("call_type" IS NULL OR "call_type" = 'call')
    AND "status" = 1
    AND "block_timestamp" < DATE_PART(EPOCH_SECOND, TO_TIMESTAMP_NTZ('2021-09-01', 'YYYY-MM-DD')) * 1e6
  GROUP BY "to_address"
),
agg_received AS (
  SELECT "address", SUM("amount") AS "total_received"
  FROM received
  GROUP BY "address"
),
sent AS (
  SELECT "from_address" AS "address", SUM("value") AS "amount"
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS"
  WHERE "receipt_status" = 1
    AND "block_timestamp" < DATE_PART(EPOCH_SECOND, TO_TIMESTAMP_NTZ('2021-09-01', 'YYYY-MM-DD')) * 1e6
  GROUP BY "from_address"
  UNION ALL
  SELECT "from_address" AS "address", SUM("value") AS "amount"
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
  WHERE ("call_type" IS NULL OR "call_type" = 'call')
    AND "status" = 1
    AND "block_timestamp" < DATE_PART(EPOCH_SECOND, TO_TIMESTAMP_NTZ('2021-09-01', 'YYYY-MM-DD')) * 1e6
  GROUP BY "from_address"
),
agg_sent AS (
  SELECT "address", SUM("amount") AS "total_sent"
  FROM sent
  GROUP BY "address"
),
gas_fees AS (
  SELECT "from_address" AS "address", SUM("gas_price" * "receipt_gas_used") AS "amount"
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS"
  WHERE "receipt_status" = 1
    AND "block_timestamp" < DATE_PART(EPOCH_SECOND, TO_TIMESTAMP_NTZ('2021-09-01', 'YYYY-MM-DD')) * 1e6
  GROUP BY "from_address"
),
agg_gas_fees AS (
  SELECT "address", SUM("amount") AS "total_gas_fee"
  FROM gas_fees
  GROUP BY "address"
),
addresses AS (
  SELECT "address" FROM agg_received
  UNION
  SELECT "address" FROM agg_sent
  UNION
  SELECT "address" FROM agg_gas_fees
),
balances AS (
  SELECT
    addresses."address",
    COALESCE(agg_received."total_received", 0) AS "total_received",
    COALESCE(agg_sent."total_sent", 0) AS "total_sent",
    COALESCE(agg_gas_fees."total_gas_fee", 0) AS "total_gas_fee"
  FROM addresses
  LEFT JOIN agg_received ON addresses."address" = agg_received."address"
  LEFT JOIN agg_sent ON addresses."address" = agg_sent."address"
  LEFT JOIN agg_gas_fees ON addresses."address" = agg_gas_fees."address"
)
SELECT "address", ROUND(("total_received" - "total_sent" - "total_gas_fee"), 4) AS "balance"
FROM balances
ORDER BY "balance" DESC NULLS LAST
LIMIT 10;