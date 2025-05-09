WITH
    -- hard-coded cut-off : 2021-09-01 00:00:00 UTC  = 1630454400 s  = 1630454400000000 μs
    "cutoff"          AS ( SELECT 1630454400000000::NUMBER AS "ts" ),

    /* 1)  Addresses that ever invoked a forbidden call_type (delegatecall ‑ callcode ‑ staticcall)
           before the cut-off – they will be excluded                                   */
    "excluded_senders" AS (
        SELECT DISTINCT LOWER("from_address")   AS "sender"
        FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES t
        JOIN   "cutoff" c
              ON t."block_timestamp" < c."ts"
        WHERE  LOWER(t."call_type") IN ('delegatecall','callcode','staticcall')
    ),

    /* 2)  Successful transactions per sender (before cut-off, receipt_status = 1)      */
    "sender_success_cnt" AS (
        SELECT  LOWER("from_address") AS "sender",
                COUNT(*)              AS "tx_cnt"
        FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS tx
        JOIN    "cutoff" c
              ON tx."block_timestamp" < c."ts"
        WHERE   tx."receipt_status" = 1
        GROUP BY 1
    ),

    /* 3)  Keep only those senders that never used forbidden call types                 */
    "eligible_senders" AS (
        SELECT s.*
        FROM   "sender_success_cnt" s
        WHERE  s."sender" NOT IN ( SELECT "sender" FROM "excluded_senders" )
    ),

    /* 4)  Address with the highest count of successful tx’s (ties broken arbitrarily)  */
    "top_sender" AS (
        SELECT  "sender"
        FROM    "eligible_senders"
        ORDER BY "tx_cnt" DESC NULLS LAST
        LIMIT 1
    ),

    /* 5)  Aggregate incoming, outgoing, and gas paid for the top address               */
    "tx_flows" AS (
        SELECT
            SUM( CASE WHEN t."from_address" = s."sender" THEN t."value"                                   END ) AS "total_sent_wei",
            SUM( CASE WHEN t."from_address" = s."sender"
                       THEN t."gas_price" * t."receipt_gas_used"                                           END ) AS "total_gas_wei",
            SUM( CASE WHEN t."to_address"   = s."sender" THEN t."value"                                   END ) AS "total_recv_wei"
        FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
        JOIN   "top_sender"  s   ON 1=1
        JOIN   "cutoff"      c   ON t."block_timestamp" < c."ts"
        WHERE  t."receipt_status" = 1
          AND ( t."from_address" = s."sender"
             OR t."to_address"   = s."sender" )
    ),

    /* 6)  Blocks mined by the same address (for base reward – 2 ETH per block)         */
    "mined_blocks" AS (
        SELECT  COUNT(*) AS "blocks_mined"
        FROM    CRYPTO.CRYPTO_ETHEREUM.BLOCKS b
        JOIN    "top_sender" s ON b."miner" = s."sender"
        JOIN    "cutoff"     c ON b."timestamp" < c."ts"
    ),

    /* 7)  Final balance in wei, then converted to Ether                                */
    "final_balance" AS (
        SELECT
              ( tf."total_recv_wei"
              - tf."total_sent_wei"
              - tf."total_gas_wei"
              + mb."blocks_mined" * 2 * POW(10,18)    /* 2 ETH static reward per block */
              )              / POW(10,18)             AS "final_balance_eth"
        FROM   "tx_flows"     tf,
               "mined_blocks" mb
    )

SELECT  "final_balance_eth"
FROM    "final_balance";