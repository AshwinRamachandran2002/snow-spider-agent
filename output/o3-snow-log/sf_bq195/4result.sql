WITH
-- -------------------------------------------------------------------
-- 1. Outgoing (-) and incoming (+) value & gas from successful L1
--    transactions before 2021-09-01
-- -------------------------------------------------------------------
txn_changes AS (
    /* sender: value + gas fee (negative) */
    SELECT
        "from_address"                                   AS address,
        -( TO_DECIMAL("value") +
           TO_DECIMAL("receipt_gas_used")
           * COALESCE( TO_DECIMAL("receipt_effective_gas_price"),
                       TO_DECIMAL("gas_price") )          )          AS delta_wei
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "block_timestamp" < 1630454400000000          -- 2021-09-01
      AND "receipt_status" = 1

    UNION ALL

    /* receiver: value (positive) */
    SELECT
        "to_address"                                     AS address,
        TO_DECIMAL("value")                              AS delta_wei
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "block_timestamp" < 1630454400000000
      AND "receipt_status" = 1
      AND "to_address" IS NOT NULL
),
-- -------------------------------------------------------------------
-- 2. Internal ETH transfers from traces (successful calls only)
--    Exclude root trace to avoid double-counting the tx record
-- -------------------------------------------------------------------
trace_changes AS (
    /* internal sender (negative) */
    SELECT
        "from_address"                                   AS address,
        -TO_DECIMAL("value")                             AS delta_wei
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "block_timestamp" < 1630454400000000
      AND "status" = 1
      AND ( "call_type" IS NULL OR "call_type" = 'call' )
      AND "trace_type" = 'call'
      AND "value" IS NOT NULL AND "value" <> 0
      AND "trace_address" IS NOT NULL AND "trace_address" <> ''

    UNION ALL

    /* internal receiver (positive) */
    SELECT
        "to_address"                                     AS address,
        TO_DECIMAL("value")                              AS delta_wei
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "block_timestamp" < 1630454400000000
      AND "status" = 1
      AND ( "call_type" IS NULL OR "call_type" = 'call' )
      AND "trace_type" = 'call'
      AND "value" IS NOT NULL AND "value" <> 0
      AND "trace_address" IS NOT NULL AND "trace_address" <> ''
),
-- -------------------------------------------------------------------
-- 3. Combine all balance deltas
-- -------------------------------------------------------------------
all_changes AS (
    SELECT * FROM txn_changes
    UNION ALL
    SELECT * FROM trace_changes
)
-- -------------------------------------------------------------------
-- 4. Aggregate and return top 10 addresses by balance (in Ether)
-- -------------------------------------------------------------------
SELECT
    address,
    ( SUM(delta_wei) / 1e18 )      AS balance_eth
FROM all_changes
GROUP BY address
ORDER BY balance_eth DESC NULLS LAST
LIMIT 10;