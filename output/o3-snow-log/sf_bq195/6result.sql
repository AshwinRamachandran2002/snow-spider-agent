-- Top 10 Ethereum addresses by cumulated balance variation
WITH
--------------------------------------------------------------------
-- 1. ETH value & gas-fee deltas coming from successful transactions
--------------------------------------------------------------------
tx_deltas AS (
    /* outgoing side (value + gas fee) */
    SELECT
        LOWER("from_address")                        AS address ,
        - (                                      
            "value"                                          -- value sent
          + COALESCE("receipt_effective_gas_price","gas_price") 
            * "receipt_gas_used"                             -- gas fee paid
        )                                    AS delta
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "block_timestamp" < 1630454400000000              -- before 2021-09-01
      AND "receipt_status" = 1                              -- successful tx
      AND "from_address" IS NOT NULL

    UNION ALL

    /* incoming side (only value) */
    SELECT
        LOWER("to_address")                  AS address ,
        "value"                              AS delta
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "block_timestamp" < 1630454400000000
      AND "receipt_status" = 1
      AND "to_address" IS NOT NULL
),
--------------------------------------------------------------------
-- 2. Internal ETH transfers recorded in traces (only type call/empty)
--------------------------------------------------------------------
trace_deltas AS (
    /* outgoing */
    SELECT
        LOWER("from_address")                AS address ,
        - "value"                            AS delta
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "block_timestamp" < 1630454400000000
      AND "status" = 1
      AND ( "call_type" IS NULL OR "call_type" = 'call' )
      AND "from_address" IS NOT NULL

    UNION ALL

    /* incoming */
    SELECT
        LOWER("to_address")                  AS address ,
        "value"                              AS delta
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "block_timestamp" < 1630454400000000
      AND "status" = 1
      AND ( "call_type" IS NULL OR "call_type" = 'call' )
      AND "to_address" IS NOT NULL
),
--------------------------------------------------------------------
-- 3. Aggregate every delta per address
--------------------------------------------------------------------
all_deltas AS (
    SELECT * FROM tx_deltas
    UNION ALL
    SELECT * FROM trace_deltas
),
balances AS (
    SELECT
        address,
        SUM(delta)        AS balance
    FROM all_deltas
    GROUP BY address
)
--------------------------------------------------------------------
-- 4. Top 10 richest addresses (balance≥0)
--------------------------------------------------------------------
SELECT
    address,
    balance
FROM balances
ORDER BY balance DESC NULLS LAST
LIMIT 10;