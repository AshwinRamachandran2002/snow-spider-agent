WITH good_txs AS (   -- successful txs before 1-Sep-2021 whose traces are plain calls
    SELECT DISTINCT t."hash"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t
    JOIN CRYPTO.CRYPTO_ETHEREUM.TRACES        tr
      ON t."hash" = tr."transaction_hash"
    WHERE t."receipt_status" = 1
      AND t."block_timestamp" < 1630454400000000     -- 2021-09-01 00:00:00 UTC
      AND tr."status" = 1
      AND (tr."call_type" IS NULL OR LOWER(tr."call_type") = 'call')
),
incoming AS (        -- total value received
    SELECT
        t."to_address"       AS "address",
        SUM(t."value")       AS "incoming_value"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    WHERE t."hash" IN (SELECT "hash" FROM good_txs)
    GROUP BY t."to_address"
),
outgoing AS (        -- total value sent + gas paid
    SELECT
        t."from_address" AS "address",
        SUM( t."value"
           + (t."receipt_gas_used" * t."receipt_effective_gas_price")
        )              AS "outgoing_plus_gas"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    WHERE t."hash" IN (SELECT "hash" FROM good_txs)
    GROUP BY t."from_address"
)
SELECT
    COALESCE(i."address", o."address")                                       AS "address",
    COALESCE(i."incoming_value", 0) - COALESCE(o."outgoing_plus_gas", 0)     AS "balance_estimate"
FROM incoming i
FULL JOIN outgoing o
  ON i."address" = o."address"
ORDER BY "balance_estimate" DESC NULLS LAST
LIMIT 10;