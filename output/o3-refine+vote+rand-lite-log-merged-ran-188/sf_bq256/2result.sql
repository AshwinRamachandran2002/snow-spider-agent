WITH
-- 1)  Cut-off timestamp for 1-Sep-2021 00:00 UTC  (micro-seconds in the raw tables)
  params AS (
    SELECT 1630454400000000::NUMBER AS cutoff_ts
  ),

-- 2)  Address that broadcast the greatest number of successful external txs
  top_sender AS (
    SELECT
      "from_address"               AS top_addr
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS , params
    WHERE  "receipt_status" = 1
       AND "block_timestamp" < params.cutoff_ts
    GROUP  BY "from_address"
    ORDER  BY COUNT(*) DESC NULLS LAST
    LIMIT  1
  ),

/* ------------------------------------------- *
 *               COMPONENT TOTALS              *
 * ------------------------------------------- */

-- 3)  Outgoing native transfers
  tx_out AS (
    SELECT
      COALESCE(SUM("value"),0)     AS wei
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t , top_sender , params
    WHERE  t."receipt_status" = 1
      AND  t."block_timestamp" < params.cutoff_ts
      AND  t."from_address" = top_sender.top_addr
  ),

-- 4)  Incoming native transfers
  tx_in AS (
    SELECT
      COALESCE(SUM("value"),0)     AS wei
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t , top_sender , params
    WHERE  t."receipt_status" = 1
      AND  t."block_timestamp" < params.cutoff_ts
      AND  t."to_address" = top_sender.top_addr
  ),

-- 5)  Gas fees paid by the address
  gas_fee AS (
    SELECT
      COALESCE(
        SUM( "receipt_gas_used"
             * COALESCE("receipt_effective_gas_price","gas_price")
           ),0)                   AS wei
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t , top_sender , params
    WHERE  t."receipt_status" = 1
      AND  t."block_timestamp" < params.cutoff_ts
      AND  t."from_address" = top_sender.top_addr
  ),

-- 6)  Internal (trace) transfers in & out
  internal_transfers AS (
    SELECT
      COALESCE(
        SUM( CASE WHEN tr."to_address"   = top_sender.top_addr
                  THEN tr."value" ELSE 0 END ),0)      AS in_wei,
      COALESCE(
        SUM( CASE WHEN tr."from_address" = top_sender.top_addr
                  THEN tr."value" ELSE 0 END ),0)      AS out_wei
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES  tr , top_sender , params
    WHERE  tr."block_timestamp" < params.cutoff_ts
      AND  tr."trace_type" = 'call'
      AND  (   tr."call_type" IS NULL
           OR  tr."call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND  ( tr."from_address" = top_sender.top_addr
          OR tr."to_address"   = top_sender.top_addr )
  ),

-- 7)  Miner (reward) transfers to the address
  rewards AS (
    SELECT
      COALESCE( SUM("value"), 0 )  AS wei
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES  tr , top_sender , params
    WHERE  tr."block_timestamp" < params.cutoff_ts
      AND  tr."trace_type"   = 'reward'
      AND  tr."to_address"   = top_sender.top_addr
  )

/* ------------------------------------------- *
 *              FINAL BALANCE                  *
 * ------------------------------------------- */
SELECT
  top_sender.top_addr                                AS "address",
  /* Components */
  tx_in.wei            AS "incoming_tx_wei",
  internal_transfers.in_wei   AS "internal_in_wei",
  rewards.wei          AS "reward_wei",
  tx_out.wei           AS "outgoing_tx_wei",
  internal_transfers.out_wei  AS "internal_out_wei",
  gas_fee.wei          AS "gas_fee_wei",

  /* Final balance in Wei */
  (  tx_in.wei
   + internal_transfers.in_wei
   + rewards.wei
   - tx_out.wei
   - internal_transfers.out_wei
   - gas_fee.wei )                       AS "final_balance_wei",

  /* Final balance converted to Ether */
  (  tx_in.wei
   + internal_transfers.in_wei
   + rewards.wei
   - tx_out.wei
   - internal_transfers.out_wei
   - gas_fee.wei ) / 1e18               AS "final_balance_eth"
FROM
  top_sender
JOIN tx_in               ON 1=1
JOIN tx_out              ON 1=1
JOIN gas_fee             ON 1=1
JOIN internal_transfers  ON 1=1
JOIN rewards             ON 1=1;