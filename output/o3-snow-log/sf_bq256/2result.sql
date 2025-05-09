WITH top_sender AS (   /* address with most successful txs before 2021-09-01 */
    SELECT "from_address"            AS addr ,
           COUNT(*)                  AS tx_cnt
    FROM   CRYPTO.CRYPTO_ETHEREUM."TRANSACTIONS"
    WHERE  "receipt_status" = 1
      AND  "block_timestamp" < 1630454400000000   -- 2021-09-01 00:00:00 UTC (µs)
    GROUP  BY "from_address"
    ORDER  BY tx_cnt DESC NULLS LAST
    LIMIT  1
),
/* outgoing native ETH (value + fee) */
ext_out AS (
    SELECT SUM( "value" +
                ( "receipt_gas_used"
                  * COALESCE("receipt_effective_gas_price","gas_price",0) )
              ) AS wei_out
    FROM   CRYPTO.CRYPTO_ETHEREUM."TRANSACTIONS" t
    JOIN   top_sender                               s ON t."from_address" = s.addr
    WHERE  t."block_timestamp" < 1630454400000000
),
/* incoming native ETH */
ext_in AS (
    SELECT SUM("value") AS wei_in
    FROM   CRYPTO.CRYPTO_ETHEREUM."TRANSACTIONS" t
    JOIN   top_sender                               s ON t."to_address" = s.addr
    WHERE  t."block_timestamp" < 1630454400000000
),
/* outgoing internal transfers (exclude delegatecall / callcode / staticcall) */
trace_out AS (
    SELECT SUM("value") AS wei_out_trace
    FROM   CRYPTO.CRYPTO_ETHEREUM."TRACES" tr
    JOIN   top_sender                             s ON tr."from_address" = s.addr
    WHERE  tr."block_timestamp" < 1630454400000000
      AND  tr."trace_type" = 'call'
      AND  COALESCE(tr."call_type",'') NOT IN ('delegatecall','callcode','staticcall')
),
/* incoming internal transfers */
trace_in AS (
    SELECT SUM("value") AS wei_in_trace
    FROM   CRYPTO.CRYPTO_ETHEREUM."TRACES" tr
    JOIN   top_sender                             s ON tr."to_address" = s.addr
    WHERE  tr."block_timestamp" < 1630454400000000
      AND  tr."trace_type" = 'call'
      AND  COALESCE(tr."call_type",'') NOT IN ('delegatecall','callcode','staticcall')
),
/* miner / uncle rewards */
reward_in AS (
    SELECT SUM("value") AS wei_reward
    FROM   CRYPTO.CRYPTO_ETHEREUM."TRACES" tr
    JOIN   top_sender                             s ON tr."to_address" = s.addr
    WHERE  tr."block_timestamp" < 1630454400000000
      AND  tr."trace_type" = 'reward'
)
SELECT
       s.addr                                                      AS "address",
       (  COALESCE(ei.wei_in        ,0)
        + COALESCE(ti.wei_in_trace  ,0)
        + COALESCE(ri.wei_reward    ,0)
        - COALESCE(eo.wei_out       ,0)
        - COALESCE(to_tr.wei_out_trace ,0)
       ) / 1e18                                                    AS "final_balance_eth"
FROM   top_sender          s
LEFT   JOIN ext_in      ei   ON 1=1
LEFT   JOIN trace_in    ti   ON 1=1
LEFT   JOIN reward_in   ri   ON 1=1
LEFT   JOIN ext_out     eo   ON 1=1
LEFT   JOIN trace_out   to_tr ON 1=1;