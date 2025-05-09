WITH
/* UTC cut-off = 1-Sep-2021 (00:00 UTC) */
params AS (
    SELECT 1630454400000000 :: NUMBER AS "cutoff_ts"
),

/* 1) address that sent the most successful tx before cut-off */
top_sender AS (
    SELECT
        t."from_address"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    CROSS JOIN params p
    WHERE t."receipt_status" = 1
      AND t."block_timestamp" < p."cutoff_ts"
    GROUP BY t."from_address"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),

/* 2) incoming native ETH (successful tx only) */
incoming AS (
    SELECT
        COALESCE(SUM(t."value"),0) AS "in_val"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN top_sender s  ON t."to_address" = s."from_address"
    CROSS JOIN params p
    WHERE t."receipt_status" = 1
      AND t."block_timestamp" < p."cutoff_ts"
),

/* 3) miner / uncle rewards to the same address                                 */
rewards AS (
    SELECT
        COALESCE(SUM(r."value"),0) AS "reward_val"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES r
    JOIN top_sender s  ON r."to_address" = s."from_address"
    CROSS JOIN params p
    WHERE r."trace_type"   = 'reward'
      AND r."block_timestamp" < p."cutoff_ts"
),

/* 4) outgoing native ETH (successful tx only)                                  */
outgoing AS (
    SELECT
        COALESCE(SUM(t."value"),0) AS "out_val"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN top_sender s ON t."from_address" = s."from_address"
    CROSS JOIN params p
    WHERE t."receipt_status" = 1
      AND t."block_timestamp" < p."cutoff_ts"
),

/* 5) gas fees paid by that address                                             */
fees AS (
    SELECT
        COALESCE(SUM(t."gas_price" * t."receipt_gas_used"),0) AS "fee_val"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN top_sender s ON t."from_address" = s."from_address"
    CROSS JOIN params p
    WHERE t."receipt_status" = 1
      AND t."block_timestamp" < p."cutoff_ts"
)

/* 6) final balance in Ether (divide Wei by 1e18)                               */
SELECT
    (incoming."in_val"
     + rewards."reward_val"
     - outgoing."out_val"
     - fees."fee_val") / 1e18                    AS "final_balance_ether"
FROM incoming, rewards, outgoing, fees;