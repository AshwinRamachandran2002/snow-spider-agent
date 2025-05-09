WITH balance_totals AS (
  SELECT "address", SUM("received") - SUM("sent") AS "net_balance"
  FROM (
    -- TRANSACTIONS received
    SELECT "to_address" AS "address", SUM("value") AS "received", 0 AS "sent"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_status" = 1 AND "receipt_gas_used" > 0 AND "to_address" IS NOT NULL
    GROUP BY "to_address"
    
    UNION ALL

    -- TRANSACTIONS sent
    SELECT "from_address" AS "address", 0 AS "received", SUM("value" + ("gas_price" * "receipt_gas_used")) AS "sent"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_status" = 1 AND "receipt_gas_used" > 0 AND "from_address" IS NOT NULL
    GROUP BY "from_address"
    
    UNION ALL

    -- TRACES received
    SELECT "to_address" AS "address", SUM("value") AS "received", 0 AS "sent"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status" = 1 AND ("call_type" IS NULL OR "call_type" = 'call') AND "to_address" IS NOT NULL
    GROUP BY "to_address"
    
    UNION ALL

    -- TRACES sent
    SELECT "from_address" AS "address", 0 AS "received", SUM("value") AS "sent"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status" = 1 AND ("call_type" IS NULL OR "call_type" = 'call') AND "from_address" IS NOT NULL
    GROUP BY "from_address"

  ) AS combined_totals
  GROUP BY "address"
)
SELECT ROUND(AVG("net_balance") / 1e15, 4) AS "average_balance_quadrillions"
FROM (
  SELECT "address", "net_balance"
  FROM balance_totals
  ORDER BY "net_balance" DESC NULLS LAST
  LIMIT 10
);