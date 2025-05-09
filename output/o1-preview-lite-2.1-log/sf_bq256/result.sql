SELECT ROUND(("balance_in_wei" / 1e18), 4) AS "Ether_balance"
FROM (
  SELECT (
    (SELECT COALESCE(SUM("value"), 0) FROM CRYPTO.CRYPTO_ETHEREUM."TRANSACTIONS"
     WHERE "to_address" = '0xea674fdde714fd979de3edf0f56aa9716b898ec8' AND "block_timestamp" < 1630454400000000)
    +
    (SELECT COALESCE(SUM("value"), 0) FROM CRYPTO.CRYPTO_ETHEREUM."TRACES"
     WHERE "to_address" = '0xea674fdde714fd979de3edf0f56aa9716b898ec8' AND "block_timestamp" < 1630454400000000
       AND ( ("trace_type" = 'call' AND "call_type" NOT IN ('delegatecall', 'callcode')) OR "trace_type" = 'reward' ))
    -
    (SELECT COALESCE(SUM("value"), 0) FROM CRYPTO.CRYPTO_ETHEREUM."TRANSACTIONS"
     WHERE "from_address" = '0xea674fdde714fd979de3edf0f56aa9716b898ec8' AND "block_timestamp" < 1630454400000000)
    -
    (SELECT COALESCE(SUM("value"), 0) FROM CRYPTO.CRYPTO_ETHEREUM."TRACES"
     WHERE "from_address" = '0xea674fdde714fd979de3edf0f56aa9716b898ec8' AND "block_timestamp" < 1630454400000000
       AND "trace_type" = 'call' AND "call_type" NOT IN ('delegatecall', 'callcode'))
    -
    (SELECT COALESCE(SUM("receipt_gas_used" * "receipt_effective_gas_price"), 0)
     FROM CRYPTO.CRYPTO_ETHEREUM."TRANSACTIONS"
     WHERE "from_address" = '0xea674fdde714fd979de3edf0f56aa9716b898ec8' AND "block_timestamp" < 1630454400000000)
  ) AS "balance_in_wei"
) AS subquery;