WITH
-- 1.  Unix‐epoch for 2021-09-01 00:00:00 UTC expressed in the micro-seconds
cutoff_ts AS (
    SELECT 1630454400 * 1000000 AS "ts"
),

-- 2.  Transactions that contain an internal call of type DELEGATECALL / CALLCODE / STATICCALL
tx_with_excluded_calls AS (
    SELECT DISTINCT "transaction_hash"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  UPPER("call_type") IN ('DELEGATECALL','CALLCODE','STATICCALL')
),

-- 3.  Successful, externally-owned transactions before the cut-off
valid_txs AS (
    SELECT  t.*
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
            JOIN cutoff_ts c ON t."block_timestamp" < c."ts"
    WHERE   t."receipt_status" = 1
      AND   t."hash" NOT IN (SELECT "transaction_hash" FROM tx_with_excluded_calls)
),

-- 4.  Wallet that initiated the greatest number of such transactions
top_wallet AS (
    SELECT  "from_address"   AS "addr"
    FROM    valid_txs
    GROUP BY "from_address"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),

/* ------------------------------------------------------------------ */
/*               BALANCE RECONCILIATION FOR THAT WALLET               */
/* ------------------------------------------------------------------ */

-- 5.  Native ETH transfers (incoming / outgoing) for that wallet
transfer_flows AS (
    SELECT
        CASE
            WHEN t."to_address"   = w."addr" THEN  t."value"                -- incoming
            ELSE                                   0
        END                                                   AS "in_val",
        CASE
            WHEN t."from_address" = w."addr" THEN  t."value"                -- outgoing
            ELSE                                   0
        END                                                   AS "out_val",
        CASE                                                    -- gas fee (only if sender)
            WHEN t."from_address" = w."addr"
                 THEN NVL(t."receipt_effective_gas_price" * t."receipt_gas_used",
                           t."gas_price" * t."receipt_gas_used")
            ELSE 0
        END                                                   AS "gas_fee"
    FROM      valid_txs  t
    CROSS JOIN top_wallet w
    WHERE     t."from_address" = w."addr"
           OR t."to_address"   = w."addr"
),

-- 6.  Miner rewards (assume 2 ETH per block) earned by that wallet
miner_rewards AS (
    SELECT  COUNT(*) * 2e18   AS "miner_reward_wei"
    FROM    CRYPTO.CRYPTO_ETHEREUM.BLOCKS  b
            JOIN cutoff_ts c ON b."timestamp" < c."ts"
            JOIN top_wallet  w ON b."miner"   = w."addr"
)

-- 7.  Final balance in Ether
SELECT
    w."addr"                                                AS "address",
    (   SUM(tf."in_val")
      + MAX(mr."miner_reward_wei")
      - SUM(tf."out_val")
      - SUM(tf."gas_fee")
    ) / 1e18                                                AS "final_balance_eth"
FROM        transfer_flows tf
CROSS JOIN  top_wallet      w
CROSS JOIN  miner_rewards   mr
GROUP BY     w."addr";