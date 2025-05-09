WITH
/* -------------------------------------------------- *
 * 1. timestamp of 2021‑09‑01 00:00:00  (μs since epoch)
 * -------------------------------------------------- */
"CUTOFF" AS (
    SELECT 1630454400000000 AS "TS"
),

/* -------------------------------------------------- *
 * 2.   successful, external‑call transactions
 *      (exclude those that involve delegatecall /
 *       callcode / staticcall inside their traces)
 * -------------------------------------------------- */
"GOOD_TX" AS (
    SELECT
        t."from_address"      AS "FROM_ADDR",
        t."hash"              AS "TX_HASH"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t, "CUTOFF"
    WHERE t."block_timestamp" <  "CUTOFF"."TS"
      AND t."receipt_status"  =  1
      AND NOT EXISTS (
              SELECT 1
              FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES tr
              WHERE  tr."transaction_hash" = t."hash"
                AND  LOWER(tr."call_type") IN ('delegatecall','callcode','staticcall')
          )
),

/* -------------------------------------------------- *
 * 3.   address that initiated the most such txs
 * -------------------------------------------------- */
"TOP_ADDR" AS (
    SELECT  "FROM_ADDR" AS "ADDR"
    FROM    "GOOD_TX"
    GROUP BY "FROM_ADDR"
    ORDER BY COUNT(*) DESC
    LIMIT   1
),

/* -------------------------------------------------- *
 * 4.   sums of native‑ETH movements in TRANSACTIONS
 *      (include gas fees paid)
 * -------------------------------------------------- */
"TX_SUMS" AS (
    SELECT
        a."ADDR",
        /* incoming ether */
        SUM(CASE WHEN t."to_address"   = a."ADDR"
                 THEN t."value" ELSE 0 END)                                   AS "IN_TX",
        /* outgoing ether (value) */
        SUM(CASE WHEN t."from_address" = a."ADDR"
                 THEN t."value" ELSE 0 END)                                   AS "OUT_TX",
        /* gas fees paid */
        SUM(CASE WHEN t."from_address" = a."ADDR"
                 THEN t."receipt_gas_used"
                      * COALESCE(t."receipt_effective_gas_price", t."gas_price")
                 ELSE 0 END)                                                  AS "GAS_FEE"
    FROM  "TOP_ADDR"             a
    JOIN  CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
          ON t."block_timestamp" < (SELECT "TS" FROM "CUTOFF")
    GROUP BY a."ADDR"
),

/* -------------------------------------------------- *
 * 5.   value‑carrying traces (exclude rewards here)
 * -------------------------------------------------- */
"TRACE_SUMS" AS (
    SELECT
        a."ADDR",
        SUM(CASE WHEN tr."to_address"   = a."ADDR"
                 THEN tr."value" ELSE 0 END)                                   AS "IN_TRACE",
        SUM(CASE WHEN tr."from_address" = a."ADDR"
                 THEN tr."value" ELSE 0 END)                                   AS "OUT_TRACE"
    FROM  "TOP_ADDR"                      a
    JOIN  CRYPTO.CRYPTO_ETHEREUM.TRACES   tr
          ON tr."block_timestamp" < (SELECT "TS" FROM "CUTOFF")
         AND tr."trace_type"  <> 'reward'          -- plain value transfers
         AND tr."value" IS NOT NULL
    GROUP BY a."ADDR"
),

/* -------------------------------------------------- *
 * 6.   miner / uncle rewards paid to the address
 * -------------------------------------------------- */
"REWARD_SUMS" AS (
    SELECT
        a."ADDR",
        SUM(CASE WHEN tr."to_address" = a."ADDR"
                 THEN tr."value" ELSE 0 END)                                   AS "REWARD_VAL"
    FROM  "TOP_ADDR"                     a
    JOIN  CRYPTO.CRYPTO_ETHEREUM.TRACES  tr
          ON tr."block_timestamp" < (SELECT "TS" FROM "CUTOFF")
         AND tr."trace_type" = 'reward'
    GROUP BY a."ADDR"
)

/* -------------------------------------------------- *
 * 7.   final ether balance in ETH (wei ÷ 1e18)
 * -------------------------------------------------- */
SELECT
    tx."ADDR"                                             AS "ADDRESS",
    ROUND( ( COALESCE(tx."IN_TX"      ,0)
           + COALESCE(tr."IN_TRACE"   ,0)
           + COALESCE(rw."REWARD_VAL" ,0)
           - COALESCE(tx."OUT_TX"     ,0)
           - COALESCE(tx."GAS_FEE"    ,0)
           - COALESCE(tr."OUT_TRACE"  ,0) )
           / 1e18 , 18)                                   AS "FINAL_BALANCE_ETHER"
FROM           "TX_SUMS"    tx
LEFT JOIN      "TRACE_SUMS" tr ON tr."ADDR" = tx."ADDR"
LEFT JOIN      "REWARD_SUMS" rw ON rw."ADDR" = tx."ADDR";