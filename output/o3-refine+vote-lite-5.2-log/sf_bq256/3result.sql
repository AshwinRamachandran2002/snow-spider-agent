WITH
/*--------------------------------------------------------------------
1.  address that sent the most successful (status = 1) transactions
    before 1‑Sep‑2021 (UTC)
--------------------------------------------------------------------*/
top_sender AS (
    SELECT
        "from_address"  AS addr,
        COUNT(*)        AS tx_cnt
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE  "block_timestamp" < 1630454400000000           -- 2021‑09‑01 00:00:00 UTC  (µs)
      AND  "receipt_status" = 1                           -- successful
    GROUP  BY "from_address"
    QUALIFY ROW_NUMBER() OVER (ORDER BY tx_cnt DESC) = 1  -- pick the highest
),
/*--------------------------------------------------------------------
2.  Wei received by that address through value‑transferring CALLs
    (exclude delegatecall/callcode/staticcall) before the cutoff
--------------------------------------------------------------------*/
incoming AS (
    SELECT
        SUM("value") AS wei_in
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES  t
    JOIN   top_sender                     s  ON t."to_address" = s.addr
    WHERE  t."block_timestamp" < 1630454400000000
      AND  t."trace_type"   = 'call'
      AND  COALESCE(t."call_type", 'call') NOT IN ('delegatecall','callcode','staticcall')
),
/*--------------------------------------------------------------------
3.  Wei sent out by that address through value‑transferring CALLs
    (same exclusions) before the cutoff
--------------------------------------------------------------------*/
outgoing AS (
    SELECT
        SUM("value") AS wei_out
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES  t
    JOIN   top_sender                     s  ON t."from_address" = s.addr
    WHERE  t."block_timestamp" < 1630454400000000
      AND  t."trace_type"   = 'call'
      AND  COALESCE(t."call_type", 'call') NOT IN ('delegatecall','callcode','staticcall')
),
/*--------------------------------------------------------------------
4.  Miner / uncle rewards the address received before the cutoff
--------------------------------------------------------------------*/
rewards AS (
    SELECT
        SUM("value") AS wei_reward
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES  t
    JOIN   top_sender                     s  ON t."to_address" = s.addr
    WHERE  t."block_timestamp" < 1630454400000000
      AND  t."trace_type" = 'reward'
),
/*--------------------------------------------------------------------
5.  Gas fees the address paid in all its successful transactions
    before the cutoff
--------------------------------------------------------------------*/
gas_fees AS (
    SELECT
        SUM(
            COALESCE("receipt_effective_gas_price","gas_price") * "receipt_gas_used"
        ) AS wei_gas
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  tx
    JOIN   top_sender                           s  ON tx."from_address" = s.addr
    WHERE  tx."block_timestamp" < 1630454400000000
      AND  tx."receipt_status" = 1
)
/*--------------------------------------------------------------------
6.  Final balance in Ether
--------------------------------------------------------------------*/
SELECT
    s.addr                            AS "ETH_ADDRESS",
    ROUND( 
        (COALESCE(i.wei_in,     0)      -- incoming transfers
       + COALESCE(r.wei_reward, 0)      -- rewards
       - COALESCE(o.wei_out,    0)      -- outgoing transfers
       - COALESCE(g.wei_gas,    0)      -- gas fees
        ) / 1e18 , 18)               AS "FINAL_BALANCE_ETH"
FROM   top_sender  s
LEFT  JOIN incoming i  ON 1=1
LEFT  JOIN outgoing o  ON 1=1
LEFT  JOIN rewards r   ON 1=1
LEFT  JOIN gas_fees g  ON 1=1;