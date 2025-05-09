WITH
  tx_received AS (
    SELECT "to_address" AS "address", SUM("value") AS "total_received_txn"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS"
    WHERE "receipt_status" = 1
      AND "block_timestamp" < 1630454400000000
    GROUP BY "to_address"
  ),
  tx_sent AS (
    SELECT "from_address" AS "address", SUM("value") AS "total_sent_txn"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS"
    WHERE "receipt_status" = 1
      AND "block_timestamp" < 1630454400000000
    GROUP BY "from_address"
  ),
  tx_gas_fees AS (
    SELECT "from_address" AS "address", SUM("gas_price" * "receipt_gas_used") AS "total_gas_fee"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS"
    WHERE "receipt_status" = 1
      AND "block_timestamp" < 1630454400000000
    GROUP BY "from_address"
  ),
  trace_received AS (
    SELECT "to_address" AS "address", SUM("value") AS "total_received_traces"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
    WHERE "status" = 1
      AND ("call_type" IS NULL OR "call_type" = 'call')
      AND "block_timestamp" < 1630454400000000
    GROUP BY "to_address"
  ),
  trace_sent AS (
    SELECT "from_address" AS "address", SUM("value") AS "total_sent_traces"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
    WHERE "status" = 1
      AND ("call_type" IS NULL OR "call_type" = 'call')
      AND "block_timestamp" < 1630454400000000
    GROUP BY "from_address"
  ),
  all_addresses AS (
    SELECT "address" FROM tx_received
    UNION
    SELECT "address" FROM tx_sent
    UNION
    SELECT "address" FROM tx_gas_fees
    UNION
    SELECT "address" FROM trace_received
    UNION
    SELECT "address" FROM trace_sent
  )
SELECT
  "a"."address",
  (COALESCE("trcv"."total_received_txn", 0) + COALESCE("trcvt"."total_received_traces", 0)
   - COALESCE("tsent"."total_sent_txn", 0) - COALESCE("tsentt"."total_sent_traces", 0)
   - COALESCE("tgf"."total_gas_fee", 0)
  ) AS "balance"
FROM
  all_addresses AS "a"
LEFT JOIN tx_received AS "trcv" ON "a"."address" = "trcv"."address"
LEFT JOIN tx_sent AS "tsent" ON "a"."address" = "tsent"."address"
LEFT JOIN tx_gas_fees AS "tgf" ON "a"."address" = "tgf"."address"
LEFT JOIN trace_received AS "trcvt" ON "a"."address" = "trcvt"."address"
LEFT JOIN trace_sent AS "tsentt" ON "a"."address" = "tsentt"."address"
WHERE
  (COALESCE("trcv"."total_received_txn", 0) + COALESCE("trcvt"."total_received_traces", 0)
   - COALESCE("tsent"."total_sent_txn", 0) - COALESCE("tsentt"."total_sent_traces", 0)
   - COALESCE("tgf"."total_gas_fee", 0)
  ) > 0
ORDER BY
  "balance" DESC NULLS LAST
LIMIT 10;