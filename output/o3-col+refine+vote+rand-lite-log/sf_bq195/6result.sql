WITH trace_hashes AS (
    -- transactions whose traces are successful and top-level (call_type NULL or 'call')
    SELECT DISTINCT "transaction_hash"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "block_timestamp" < 1630454400000000          -- before 2021-09-01 UTC
      AND "status" = 1
      AND ( "call_type" IS NULL OR "call_type" = 'call' )
),
qualified_tx AS (
    -- successful value transfers that meet the trace filter
    SELECT *
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "hash" IN (SELECT "transaction_hash" FROM trace_hashes)
      AND "block_timestamp" < 1630454400000000
      AND "receipt_status" = 1
),
deltas AS (
    -- debits for senders (value + gas) and credits for receivers (value)
    SELECT
        "from_address" AS "address",
        - ( "value"::DECIMAL(38,0)
            + COALESCE("receipt_effective_gas_price"::DECIMAL(38,0),
                       "gas_price"::DECIMAL(38,0))
            * "receipt_gas_used"::DECIMAL(38,0) ) AS "delta"
    FROM qualified_tx
    UNION ALL
    SELECT
        "to_address"   AS "address",
        "value"::DECIMAL(38,0) AS "delta"
    FROM qualified_tx
)
-- top 10 addresses by cumulative balance (credits ‑ debits)
SELECT
    "address",
    SUM("delta") AS "net_balance_change"
FROM deltas
GROUP BY "address"
ORDER BY "net_balance_change" DESC NULLS LAST
LIMIT 10;