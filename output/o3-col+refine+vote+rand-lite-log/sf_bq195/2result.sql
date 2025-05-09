WITH qualifying_tx AS (
    SELECT
        tx."hash",
        tx."from_address",
        tx."to_address",
        tx."value",
        tx."receipt_gas_used"                                          AS "gas_used",
        tx."receipt_effective_gas_price"                               AS "gas_price",
        (tx."receipt_gas_used" * tx."receipt_effective_gas_price")     AS "gas_fee"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS   tx
    LEFT JOIN CRYPTO.CRYPTO_ETHEREUM.TRACES    tr
           ON  tr."transaction_hash" = tx."hash"
           AND tr."trace_address"   = '0'
    WHERE tx."block_timestamp" < 1630454400000000      -- before 2021-09-01 (UTC)
      AND tx."receipt_status" = 1                      -- successful txs
      AND (tr."call_type" IS NULL OR tr."call_type" = 'call')   -- keep simple calls
),
balance_changes AS (
    /* outgoing (value + gas) */
    SELECT
        qt."from_address"          AS "address",
        -(qt."value" + qt."gas_fee") AS "delta_wei"
    FROM qualifying_tx qt

    UNION ALL

    /* incoming (value only) */
    SELECT
        qt."to_address"            AS "address",
        qt."value"                 AS "delta_wei"
    FROM qualifying_tx qt
    WHERE qt."to_address" IS NOT NULL
)
SELECT
    "address",
    SUM("delta_wei") AS "net_balance_wei"
FROM balance_changes
GROUP BY "address"
ORDER BY "net_balance_wei" DESC NULLS LAST
LIMIT 10;