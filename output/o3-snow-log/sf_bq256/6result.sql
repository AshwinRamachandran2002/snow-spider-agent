WITH cutoff AS (                                                    -- 2021-09-01 00:00:00 UTC
    SELECT 1630454400000000::NUMBER AS "ts"
),
/* ------------------------------------------------------------
   1. Address with the most successful transactions (< cut-off)
   ------------------------------------------------------------ */
successful_txs AS (
    SELECT
        "from_address"                                   AS "addr",
        COUNT(*)                                         AS "tx_cnt"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS, cutoff
    WHERE "block_timestamp" < cutoff."ts"
      AND "receipt_status" = 1
    GROUP BY "from_address"
),
top_addr AS (
    SELECT "addr"
    FROM successful_txs
    QUALIFY ROW_NUMBER() OVER (ORDER BY "tx_cnt" DESC NULLS LAST) = 1
),
/* ------------------------------------------------------------
   2. Native (external) transaction flows for that address
   ------------------------------------------------------------ */
tx_flows AS (
    SELECT
        SUM( CASE WHEN t."to_address"   = ta."addr" THEN t."value" ELSE 0 END )                                          AS "in_val",
        SUM( CASE WHEN t."from_address" = ta."addr"
                  THEN t."value" + COALESCE(t."receipt_effective_gas_price", t."gas_price") * t."receipt_gas_used"
                  ELSE 0
             END )                                                                                                       AS "out_val"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN top_addr  ta   ON 1=1
    JOIN cutoff    c    ON t."block_timestamp" < c."ts"
),
/* ------------------------------------------------------------
   3. Internal transfers & rewards from traces
      – exclude delegatecall / callcode / staticcall
   ------------------------------------------------------------ */
trace_flows AS (
    SELECT
        SUM( CASE WHEN tr."to_address"   = ta."addr" THEN tr."value" ELSE 0 END ) AS "in_val",
        SUM( CASE WHEN tr."from_address" = ta."addr" THEN tr."value" ELSE 0 END ) AS "out_val"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
    JOIN top_addr  ta   ON 1=1
    JOIN cutoff    c    ON tr."block_timestamp" < c."ts"
    WHERE tr."status" = 1
      AND ( tr."call_type" IS NULL
            OR tr."call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND tr."trace_type" IN ('call','create','suicide','reward')
)
/* ------------------------------------------------------------
   4. Final Ether balance (Wei → Ether)
   ------------------------------------------------------------ */
SELECT
    ta."addr"                                                                                           AS "ethereum_address",
    ( tx."in_val"  + tr."in_val"
    - tx."out_val" - tr."out_val" ) / 1e18                                                              AS "final_balance_ether"
FROM top_addr      ta
JOIN tx_flows      tx ON 1=1
JOIN trace_flows   tr ON 1=1;