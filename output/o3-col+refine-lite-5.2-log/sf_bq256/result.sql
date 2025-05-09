WITH
-- 1) fixed cutoff timestamp (2021‑09‑01 00:00:00 UTC)
cutoff AS (
    SELECT 1630454400000000::NUMBER AS ts
),

-- 2) address that signed the most successful transactions before cutoff
busiest AS (
    SELECT
        "from_address" AS addr,
        COUNT(*)       AS tx_cnt
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS, cutoff
    WHERE "receipt_status" = 1
      AND "block_timestamp" < cutoff.ts
    GROUP BY "from_address"
    ORDER BY tx_cnt DESC NULLS LAST
    LIMIT 1
),

-- 3) incoming native‑ETH transfers (plain CALLs, exclude delegate/static/callcode)
inc AS (
    SELECT COALESCE(SUM("value"),0) AS in_wei
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES t
    JOIN busiest b   ON t."to_address" = b.addr
    JOIN cutoff      ON t."block_timestamp" < cutoff.ts
    WHERE t."trace_type" = 'call'
      AND (t."call_type" IS NULL
           OR LOWER(t."call_type") NOT IN ('delegatecall','staticcall','callcode'))
),

-- 4) outgoing native‑ETH transfers
out AS (
    SELECT COALESCE(SUM("value"),0) AS out_wei
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES t
    JOIN busiest b   ON t."from_address" = b.addr
    JOIN cutoff      ON t."block_timestamp" < cutoff.ts
    WHERE t."trace_type" = 'call'
      AND (t."call_type" IS NULL
           OR LOWER(t."call_type") NOT IN ('delegatecall','staticcall','callcode'))
),

-- 5) miner rewards credited to the address
rew AS (
    SELECT COALESCE(SUM("value"),0) AS reward_wei
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES t
    JOIN busiest b   ON t."to_address" = b.addr
    JOIN cutoff      ON t."block_timestamp" < cutoff.ts
    WHERE t."trace_type" = 'reward'
),

-- 6) total gas fees (successful txs) paid by the address
gas AS (
    SELECT COALESCE(SUM("receipt_gas_used" * "receipt_effective_gas_price"),0) AS gas_wei
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN busiest b   ON t."from_address" = b.addr
    JOIN cutoff      ON t."block_timestamp" < cutoff.ts
    WHERE t."receipt_status" = 1
)

-- 7) final ETH balance (Wei → Ether)
SELECT
    b.addr                                           AS address,
    inc.in_wei,
    out.out_wei,
    rew.reward_wei,
    gas.gas_wei,
    (inc.in_wei + rew.reward_wei - out.out_wei - gas.gas_wei) / 1e18 AS final_balance_eth
FROM busiest b
CROSS JOIN inc
CROSS JOIN out
CROSS JOIN rew
CROSS JOIN gas;