/* -----------------------------------------------------------
   1.  Find the address that initiated the most successful
       transactions (receipt_status = 1) executed BEFORE
       2021-09-01 UTC, while dropping any transactions that
       involve traces whose call_type is
       delegatecall / callcode / staticcall.
   2.  For that top-sender, work out its native ETH balance
       change before the same cut-off:
         + native incoming transfers
         + miner–reward transfers
         – native outgoing transfers
         – gas fees paid
   3.  Return the final balance in Ether.
------------------------------------------------------------ */
WITH cutoff AS (
    SELECT 1630454400000000::NUMBER AS ts               -- 2021-09-01T00:00:00Z (µs)
),

/* All tx-hashes that must be ignored because they contain one
   of the excluded low-level call types.                    */
excluded_call_txs AS (
    SELECT DISTINCT "transaction_hash"
    FROM   CRYPTO.CRYPTO_ETHEREUM."TRACES"
    WHERE  LOWER("call_type") IN ('delegatecall','callcode','staticcall')
      AND  "block_timestamp"  < (SELECT ts FROM cutoff)
),

/* Successful transactions before the cut-off and NOT in the
   above exclusion set.                                     */
good_txs AS (
    SELECT *
    FROM   CRYPTO.CRYPTO_ETHEREUM."TRANSACTIONS"
    WHERE  "receipt_status"   = 1
      AND  "block_timestamp"  < (SELECT ts FROM cutoff)
      AND  "hash" NOT IN (SELECT "transaction_hash" FROM excluded_call_txs)
),

/* Address that sent the most such transactions.            */
top_sender AS (
    SELECT  "from_address",
            COUNT(*) AS tx_cnt
    FROM    good_txs
    GROUP BY "from_address"
    ORDER BY tx_cnt DESC NULLS LAST
    LIMIT   1
),

/* Outgoing native value and gas cost for the top sender.   */
sent AS (
    SELECT  COALESCE(SUM("value"), 0)                                   AS wei_out,
            COALESCE(SUM("gas_price" * "receipt_gas_used"), 0)          AS gas_wei
    FROM    good_txs
    WHERE   "from_address" = (SELECT "from_address" FROM top_sender)
),

/* Incoming native value to the top sender.                  */
recv AS (
    SELECT  COALESCE(SUM("value"), 0) AS wei_in
    FROM    good_txs
    WHERE   "to_address" = (SELECT "from_address" FROM top_sender)
),

/* Miner-reward transfers to that address.                   */
rewards AS (
    SELECT  COALESCE(SUM("value"), 0) AS reward_wei
    FROM    CRYPTO.CRYPTO_ETHEREUM."TRACES"
    WHERE   "to_address"     = (SELECT "from_address" FROM top_sender)
      AND   "trace_type"     = 'reward'
      AND   "block_timestamp" < (SELECT ts FROM cutoff)
)

/* --------------------   Final balance   ------------------- */
SELECT
       (recv.wei_in
     +  rewards.reward_wei
     -  sent.wei_out
     -  sent.gas_wei) / 1e18                       AS "final_balance_eth"
FROM   sent, recv, rewards;