WITH
/* ----------------------------------------------------------------------
1.  Only successful external transactions (exclude those that ever use
    DELEGATECALL / CALLCODE / STATICCALL before 1‑Sep‑2021 00:00:00 UTC)
---------------------------------------------------------------------- */
tx_ok AS (
    SELECT  *
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t
    WHERE   t."block_timestamp" < 1630454400000000          -- 2021‑09‑01 UTC
      AND   t."receipt_status" = 1                          -- succeeded
      AND NOT EXISTS (       -- eliminate any tx that contains the forbidden call‑types
              SELECT 1
              FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES  tr
              WHERE  tr."transaction_hash" = t."hash"
                AND  tr."call_type" IN ('delegatecall','callcode','staticcall')
          )
),

/* ----------------------------------------------------------------------
2.  Address that initiated the most such successful transactions
---------------------------------------------------------------------- */
top_sender AS (
    SELECT  "from_address"         AS address,
            COUNT(*)               AS tx_cnt
    FROM    tx_ok
    GROUP  BY  "from_address"
    ORDER BY tx_cnt DESC NULLS LAST
    LIMIT   1
),

/* ----------------------------------------------------------------------
3.  Money movements for that address
---------------------------------------------------------------------- */
addr_txs AS (
    SELECT  t.*,
            CASE WHEN t."receipt_effective_gas_price" IS NOT NULL
                 THEN t."receipt_effective_gas_price"
                 ELSE t."gas_price"
            END                                           AS gas_price_used
    FROM    tx_ok t
    JOIN    top_sender s
           ON t."from_address" = s.address
           OR t."to_address"   = s.address
),

/* incoming (Wei) ------------------------------------------------------ */
incoming AS (
    SELECT  COALESCE(SUM("value"),0) AS wei_in
    FROM    addr_txs
    JOIN    top_sender s
           ON addr_txs."to_address" = s.address
),

/* outgoing transfer value (Wei) --------------------------------------- */
outgoing AS (
    SELECT  COALESCE(SUM("value"),0) AS wei_out
    FROM    addr_txs
    JOIN    top_sender s
           ON addr_txs."from_address" = s.address
),

/* outgoing gas cost (Wei) -------------------------------------------- */
gasfee AS (
    SELECT  COALESCE(SUM("receipt_gas_used" * gas_price_used),0) AS wei_gas
    FROM    addr_txs
    JOIN    top_sender s
           ON addr_txs."from_address" = s.address
),

/* ----------------------------------------------------------------------
4.  Block‑mining rewards earned by that address before the cut‑off.
    Reward schedule (pre‑Merge):
        < 4 370 000 : 5 ETH
        < 7 280 000 : 3 ETH
        otherwise   : 2 ETH
---------------------------------------------------------------------- */
rewards AS (
    SELECT  COALESCE(
            SUM(
                CASE
                     WHEN b."number" <  4370000 THEN 5000000000000000000
                     WHEN b."number" <  7280000 THEN 3000000000000000000
                     ELSE                           2000000000000000000
                END
            ),0)                                           AS wei_reward
    FROM    CRYPTO.CRYPTO_ETHEREUM.BLOCKS  b
    JOIN    top_sender  s
           ON b."miner"           = s.address
    WHERE   b."timestamp"         < 1630454400000000        -- 2021‑09‑01 UTC
)

/* ----------------------------------------------------------------------
5.  Final balance in Ether
---------------------------------------------------------------------- */
SELECT
        s.address                                                    AS "ADDRESS",
        (   inc.wei_in
          + rew.wei_reward
          - out.wei_out
          - gas.wei_gas
        ) / 1e18                                                     AS "FINAL_BALANCE_ETHER"
FROM    top_sender  s
        CROSS JOIN incoming  inc
        CROSS JOIN outgoing  out
        CROSS JOIN gasfee   gas
        CROSS JOIN rewards  rew;