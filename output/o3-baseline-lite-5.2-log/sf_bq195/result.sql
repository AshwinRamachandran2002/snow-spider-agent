WITH valid_tx AS (
    -- keep only successful transactions that have
    --   • receipt_status = 1
    --   • at least one trace whose call_type is NULL or = 'call'
    --   • block timestamp prior to 1‑Sep‑2021
    SELECT
        t."hash",
        t."from_address",
        t."to_address",
        t."value",
        /* fee = gas_used * effective_gas_price (pre‑ or post‑EIP‑1559) */
        COALESCE(t."receipt_gas_used", t."gas") 
        * COALESCE(t."receipt_effective_gas_price", t."gas_price") AS "fee"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t
    INNER JOIN (
        SELECT DISTINCT "transaction_hash"
        FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
        WHERE ("call_type" IS NULL OR LOWER("call_type") = 'call')
          AND "status" = 1
    ) tr
      ON tr."transaction_hash" = t."hash"
    WHERE t."receipt_status" = 1
      AND t."block_timestamp" < 1630454400000000  -- 2021‑09‑01 00:00:00 UTC (µs)
),
movements AS (
    /* sender: value + fee leaves the account */
    SELECT
        v."from_address"   AS "address",
        - (v."value" + v."fee")::NUMBER AS delta
    FROM valid_tx v
    WHERE v."from_address" IS NOT NULL

    UNION ALL

    /* receiver: value enters the account */
    SELECT
        v."to_address"     AS "address",
        v."value"::NUMBER  AS delta
    FROM valid_tx v
    WHERE v."to_address" IS NOT NULL
)
SELECT
    "address",
    SUM(delta) AS "balance_wei"
FROM movements
WHERE "address" IS NOT NULL
GROUP BY "address"
ORDER BY "balance_wei" DESC NULLS LAST
LIMIT 10;