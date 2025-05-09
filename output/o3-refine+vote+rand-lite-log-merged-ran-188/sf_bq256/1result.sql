/*  FINAL ETHER BALANCE OF THE MOST-ACTIVE SENDER (before 2021-09-01 UTC)  */

WITH
/* ------------------------------------------------------------ */
/* universal cut-off                                            */
cutoff AS (
  SELECT 1630454400000000::NUMBER AS "ts"   -- 2021-09-01 00:00:00 UTC
),

/* ------------------------------------------------------------ */
/* 1) most-active sender (successful txs, filter forbidden call types) */
top_sender AS (
  SELECT
         t."from_address",
         COUNT(*) AS "tx_cnt"
  FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
  JOIN   cutoff c
    ON   t."block_timestamp" < c."ts"
  WHERE  t."receipt_status" = 1
    AND  NOT EXISTS (
           SELECT 1
           FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES tr
           WHERE  tr."transaction_hash" = t."hash"
             AND  tr."call_type" IN ('delegatecall','callcode','staticcall')
         )
  GROUP  BY t."from_address"
  ORDER  BY "tx_cnt" DESC NULLS LAST
  LIMIT  1
),

/* ------------------------------------------------------------ */
/* 2) all relevant txs involving that address (same call-type filter) */
tx_filtered AS (
  SELECT
         t.*,
         COALESCE(t."receipt_effective_gas_price", t."gas_price") AS "eff_gas_price"
  FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
  JOIN   cutoff     c  ON t."block_timestamp" < c."ts"
  JOIN   top_sender s  ON t."from_address" = s."from_address"
                      OR t."to_address"   = s."from_address"
  WHERE  NOT EXISTS (
           SELECT 1
           FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES tr
           WHERE  tr."transaction_hash" = t."hash"
             AND  tr."call_type" IN ('delegatecall','callcode','staticcall')
         )
),

/* ------------------------------------------------------------ */
/* 3) aggregate transfers & gas                                 */
balances AS (
  SELECT
         COALESCE(SUM(CASE WHEN t."to_address"   = s."from_address" THEN t."value" END),0)                       AS "incoming_wei",
         COALESCE(SUM(CASE WHEN t."from_address" = s."from_address" THEN t."value" END),0)                       AS "outgoing_wei",
         COALESCE(SUM(CASE WHEN t."from_address" = s."from_address"
                           THEN t."eff_gas_price" * t."receipt_gas_used" END),0)                                 AS "gas_wei"
  FROM   tx_filtered t
  CROSS  JOIN top_sender s
),

/* ------------------------------------------------------------ */
/* 4) block rewards mined by the address (approximate schedule) */
rewards AS (
  SELECT
         COALESCE(SUM(
           CASE
             WHEN b."number" <  4370000 THEN 5   -- pre-Byzantium
             WHEN b."number" <  7280000 THEN 3   -- Byzantium – Constantinople
             ELSE 2                              -- after Constantinople
           END
         ),0) * 1e18  AS "rewards_wei"
  FROM   CRYPTO.CRYPTO_ETHEREUM.BLOCKS b
  JOIN   cutoff     c ON b."timestamp" < c."ts"
  JOIN   top_sender s ON b."miner"     = s."from_address"
)

/* ------------------------------------------------------------ */
/* 5) final balance (Wei → Ether)                               */
SELECT
       s."from_address"                                                   AS "address",
       ( (bal."incoming_wei" + rew."rewards_wei")
         - (bal."outgoing_wei" + bal."gas_wei") ) / 1e18                 AS "final_balance_eth"
FROM   top_sender s
CROSS  JOIN balances bal
CROSS  JOIN rewards  rew;