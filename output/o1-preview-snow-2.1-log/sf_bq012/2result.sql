WITH top_balances AS (
  SELECT "address", SUM("net_value") AS "balance"
  FROM (
    -- From transactions
    SELECT "from_address" AS "address", - ("value" + ("receipt_gas_used" * "gas_price")) AS "net_value"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_status" = 1 AND "receipt_gas_used" IS NOT NULL

    UNION ALL

    SELECT "to_address" AS "address", "value" AS "net_value"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_status" = 1

    -- From traces
    UNION ALL

    SELECT "from_address" AS "address", - "value" AS "net_value"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status" = 1 AND ("call_type" IS NULL OR "call_type" = 'call')

    UNION ALL

    SELECT "to_address" AS "address", "value" AS "net_value"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status" = 1 AND ("call_type" IS NULL OR "call_type" = 'call')
  ) AS t
  WHERE "address" IS NOT NULL
  GROUP BY "address"
  ORDER BY "balance" DESC NULLS LAST
  LIMIT 10
)
SELECT ROUND(AVG("balance") / 1e15, 4) AS "Average_balance_quadrillions"
FROM top_balances;