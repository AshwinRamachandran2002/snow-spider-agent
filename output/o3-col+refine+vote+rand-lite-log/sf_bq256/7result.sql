WITH
-- 1) timestamp limit
cutoff AS (
    SELECT 1630454400000000::NUMBER AS ts              -- 2021-09-01 00:00:00 UTC in µs
),

-- 2) count successful transactions per sender before the cut-off
sender_counts AS (
    SELECT
        "from_address",
        COUNT(*) AS succ_tx_cnt
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN cutoff c ON t."block_timestamp" < c.ts
    WHERE t."receipt_status" = 1
    GROUP BY "from_address"
),

-- 3) address that sent the highest number of successful txs
top_sender AS (
    SELECT "from_address" AS addr
    FROM sender_counts
    ORDER BY succ_tx_cnt DESC NULLS LAST
    LIMIT 1
),

/* ----------  AGGREGATE OUTFLOWS  ---------- */

-- 4) native ETH sent in successful root-level transactions
tx_out AS (
    SELECT SUM("value") AS wei_out_tx
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN cutoff c   ON t."block_timestamp" < c.ts
    JOIN top_sender s ON t."from_address" = s.addr
    WHERE t."receipt_status" = 1
),

-- 5) gas fees paid by the address
gas_out AS (
    SELECT SUM("receipt_gas_used" * "receipt_effective_gas_price") AS wei_out_gas
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN cutoff c   ON t."block_timestamp" < c.ts
    JOIN top_sender s ON t."from_address" = s.addr
    WHERE t."receipt_status" = 1
),

-- 6) internal calls (plain `call`) that move ETH out of the address
internal_out AS (
    SELECT SUM("value") AS wei_out_internal
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
    JOIN cutoff c   ON tr."block_timestamp" < c.ts
    JOIN top_sender s ON tr."from_address" = s.addr
    WHERE tr."trace_type" = 'call'
      AND tr."call_type" = 'call'          -- exclude delegatecall / callcode / staticcall
),

/* ----------  AGGREGATE INFLOWS  ---------- */

-- 7) native ETH received in successful root-level transactions
tx_in AS (
    SELECT SUM("value") AS wei_in_tx
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN cutoff c   ON t."block_timestamp" < c.ts
    JOIN top_sender s ON t."to_address" = s.addr
    WHERE t."receipt_status" = 1
),

-- 8) internal calls (plain `call`) that send ETH to the address
internal_in AS (
    SELECT SUM("value") AS wei_in_internal
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
    JOIN cutoff c   ON tr."block_timestamp" < c.ts
    JOIN top_sender s ON tr."to_address" = s.addr
    WHERE tr."trace_type" = 'call'
      AND tr."call_type" = 'call'
),

-- 9) block / uncle rewards paid to the address
reward_in AS (
    SELECT SUM("value") AS wei_in_reward
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
    JOIN cutoff c   ON tr."block_timestamp" < c.ts
    JOIN top_sender s ON tr."to_address" = s.addr
    WHERE tr."trace_type" = 'reward'
)

/* ----------  FINAL BALANCE  ---------- */
SELECT
    s.addr                                         AS "address",
    (
        NVL(txi.wei_in_tx,        0) +
        NVL(ini.wei_in_internal,  0) +
        NVL(rwd.wei_in_reward,    0) -
        NVL(txo.wei_out_tx,       0) -
        NVL(ino.wei_out_internal, 0) -
        NVL(gas.wei_out_gas,      0)
    ) / 1e18                                       AS "final_balance_eth"
FROM top_sender      s
LEFT JOIN tx_in      txi ON 1=1
LEFT JOIN internal_in ini ON 1=1
LEFT JOIN reward_in  rwd ON 1=1
LEFT JOIN tx_out     txo ON 1=1
LEFT JOIN internal_out ino ON 1=1
LEFT JOIN gas_out    gas ON 1=1;