WITH
-- successful traces of interest (no call_type or 'call')
"FILTERED_TRACES" AS (
    SELECT DISTINCT "transaction_hash"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "status" = 1
      AND ("call_type" IS NULL OR "call_type" = 'call')
      AND "block_timestamp" < 1630454400000000      -- 2021‑09‑01T00:00:00Z (µs)
),
-- related successful transactions before 1‑Sep‑2021
"TX" AS (
    SELECT
        t."hash",
        t."from_address",
        t."to_address",
        CAST(t."value" AS NUMBER(38,0))                             AS "value_wei",
        CAST(t."receipt_gas_used" AS NUMBER(38,0))                  AS "gas_used",
        CAST(COALESCE(t."receipt_effective_gas_price",
                      t."gas_price") AS NUMBER(38,0))               AS "gas_price_wei"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN "FILTERED_TRACES" f
          ON t."hash" = f."transaction_hash"
    WHERE t."block_timestamp" < 1630454400000000
      AND t."receipt_status" = 1                                    -- successful tx
),
-- balance changes per address (debits & credits)
"CHANGES" AS (
    SELECT
        "from_address"  AS "address",
        -1 * ("value_wei" + "gas_used" * "gas_price_wei") AS "delta_wei"
    FROM "TX"
    WHERE "from_address" IS NOT NULL
    
    UNION ALL
    
    SELECT
        "to_address"    AS "address",
        "value_wei"                          AS "delta_wei"
    FROM "TX"
    WHERE "to_address" IS NOT NULL
),
-- aggregate balances
"BALANCES" AS (
    SELECT
        "address",
        SUM("delta_wei") / POW(10,18) AS "balance_eth"              -- convert Wei → ETH
    FROM "CHANGES"
    GROUP BY "address"
)
SELECT
    "address",
    "balance_eth"
FROM "BALANCES"
ORDER BY "balance_eth" DESC NULLS LAST, "address"
LIMIT 10;