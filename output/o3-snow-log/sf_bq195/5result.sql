WITH
/* ----------------------------------------------------------------------
   All ether movements coming from internal & external calls
---------------------------------------------------------------------- */
trace_transfers AS (
    /* Credit the recipient */
    SELECT
        LOWER("to_address")                       AS address,
        TO_NUMBER("value")                        AS wei_delta
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "status" = 1
      AND ("call_type" IS NULL OR "call_type" = 'call')
      AND "block_timestamp" < 1630454400000000          -- 2021-09-01 (µs)
      AND "to_address" IS NOT NULL

    UNION ALL

    /* Debit the sender */
    SELECT
        LOWER("from_address")                     AS address,
        - TO_NUMBER("value")                      AS wei_delta
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "status" = 1
      AND ("call_type" IS NULL OR "call_type" = 'call')
      AND "block_timestamp" < 1630454400000000
      AND "from_address" IS NOT NULL
),

/* ----------------------------------------------------------------------
   Gas fees paid by transaction senders
---------------------------------------------------------------------- */
gas_fees AS (
    SELECT
        LOWER("from_address")                                              AS address,
        - ( "receipt_gas_used"
            * COALESCE("receipt_effective_gas_price", "gas_price") )       AS wei_delta
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "receipt_status" = 1
      AND "block_timestamp" < 1630454400000000
      AND "from_address" IS NOT NULL
),

/* ----------------------------------------------------------------------
   Combine value transfers and gas fees
---------------------------------------------------------------------- */
all_movements AS (
    SELECT * FROM trace_transfers
    UNION ALL
    SELECT * FROM gas_fees
)

/* ----------------------------------------------------------------------
   Aggregate per address and return top 10
---------------------------------------------------------------------- */
SELECT
    address,
    ROUND( SUM(wei_delta) / 1e18 , 4) AS ether_balance   -- balance in ETH
FROM all_movements
GROUP BY address
ORDER BY ether_balance DESC NULLS LAST
LIMIT 10;