WITH
    /* 2021‑09‑01 00:00:00 UTC in micro‑seconds */
    params AS (
        SELECT 1630454400000000 AS "cutoff_ts"
    ),

/* -----------------------------------------------------------------
   1. keep only successful user‑initiated txs whose top‑level trace
      is NOT a  delegatecall / callcode / staticcall
------------------------------------------------------------------*/
    valid_transactions AS (
        SELECT
            t."hash",
            t."from_address"
        FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
        JOIN params p
              ON t."block_timestamp" < p."cutoff_ts"
        WHERE t."receipt_status" = 1
          AND NOT EXISTS (       /* filter unwanted call types        */
                SELECT 1
                FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
                WHERE tr."transaction_hash" = t."hash"
                  AND (tr."trace_address" IS NULL
                       OR tr."trace_address" IN ('', '0'))
                  AND LOWER(tr."call_type") IN
                         ('delegatecall','callcode','staticcall')
          )
    ),

/* -----------------------------------------------------------------
   2. address that sent the largest number of such txs
------------------------------------------------------------------*/
    top_sender AS (
        SELECT  "from_address"     AS addr,
                COUNT(*)           AS tx_cnt
        FROM    valid_transactions
        GROUP BY  "from_address"
        QUALIFY  ROW_NUMBER() OVER (ORDER BY tx_cnt DESC, addr) = 1
    ),

/* -----------------------------------------------------------------
   3. Ether (wei) that moved to / from that address in traces
      – include normal calls, suicides, and miner rewards
      – exclude delegatecall / callcode / staticcall
------------------------------------------------------------------*/
    trace_flows AS (
        SELECT
              CASE
                  WHEN tr."to_address"   = ts.addr THEN  (tr."value")/1e18
                  WHEN tr."from_address" = ts.addr THEN -(tr."value")/1e18
                  ELSE 0
              END  AS delta_ether
        FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
        CROSS JOIN top_sender ts
        JOIN params p
              ON tr."block_timestamp" < p."cutoff_ts"
        WHERE tr."trace_type" IN ('call','suicide','reward')
          AND (tr."to_address"   = ts.addr
               OR tr."from_address" = ts.addr)
          AND (tr."call_type" IS NULL
               OR LOWER(tr."call_type") NOT IN
                      ('delegatecall','callcode','staticcall'))
    ),

/* -----------------------------------------------------------------
   4. Gas fees paid by that address (successful txs only)
------------------------------------------------------------------*/
    gas_fees AS (
        SELECT  SUM(
                   COALESCE(t."receipt_effective_gas_price",
                            t."gas_price")
                   * t."receipt_gas_used" / 1e18
               ) AS gas_spent_ether
        FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
        CROSS JOIN top_sender ts
        JOIN params p
              ON t."block_timestamp" < p."cutoff_ts"
        WHERE t."from_address"   = ts.addr
          AND t."receipt_status" = 1
    )

/* -----------------------------------------------------------------
   5. final balance (incoming – outgoing – gas) in Ether
------------------------------------------------------------------*/
SELECT
       ts.addr                                                   AS "ethereum_address",
       ROUND( ( SELECT COALESCE(SUM(delta_ether),0)
                FROM   trace_flows )
              - gas_fees.gas_spent_ether
            , 18)                                                AS "final_balance_in_ether"
FROM   top_sender ts
CROSS JOIN gas_fees;