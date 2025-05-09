WITH

-- Successful external transactions before 1-Sep-2021 (micro-seconds: 1630454400000000)
ext_tx AS (
    SELECT  
        "from_address"  AS addr,
        - ( "value"                               -- value sent
            + COALESCE("receipt_gas_used",0)
              * COALESCE("receipt_effective_gas_price","gas_price",0)   -- gas fee
          )                    AS delta
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "receipt_status" = 1
      AND "block_timestamp" < 1630454400000000
      AND "from_address" IS NOT NULL

    UNION ALL

    SELECT  
        "to_address"     AS addr,
        "value"          AS delta                -- value received
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "receipt_status" = 1
      AND "block_timestamp" < 1630454400000000
      AND "to_address" IS NOT NULL
),

-- Successful traces (internal transfers) with no call_type or call_type = 'call'
int_traces AS (
    SELECT  
        "from_address"   AS addr,
        - "value"        AS delta
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "status" = 1
      AND "block_timestamp" < 1630454400000000
      AND ( "call_type" IS NULL OR LOWER("call_type") = 'call' )
      AND "from_address" IS NOT NULL
      AND "value" IS NOT NULL

    UNION ALL

    SELECT  
        "to_address"     AS addr,
        "value"          AS delta
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "status" = 1
      AND "block_timestamp" < 1630454400000000
      AND ( "call_type" IS NULL OR LOWER("call_type") = 'call' )
      AND "to_address" IS NOT NULL
      AND "value" IS NOT NULL
),

-- Combine all balance deltas
all_deltas AS (
    SELECT * FROM ext_tx
    UNION ALL
    SELECT * FROM int_traces
)

-- Aggregate and rank
SELECT
    addr                     AS "address",
    SUM(delta)               AS "balance"
FROM all_deltas
GROUP BY addr
ORDER BY "balance" DESC NULLS LAST
LIMIT 10;