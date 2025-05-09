WITH cutoff AS (  -- 1-Sep-2021 00:00:00 UTC in micro-seconds
    SELECT 1630454400000000::NUMBER AS ts
),

/* 1. Address with most successful txs before cut-off */
top_sender AS (
    SELECT  "from_address" AS addr
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN    cutoff c  ON t."block_timestamp" < c.ts
    WHERE   t."receipt_status" = 1
    GROUP BY "from_address"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT   1
),

/* 2. Transactions that include disallowed call types */
bad_tx AS (
    SELECT DISTINCT "transaction_hash"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES tr
    JOIN   cutoff c  ON tr."block_timestamp" < c.ts
    WHERE  LOWER(tr."call_type") IN ('delegatecall','callcode','staticcall')
),

/* 3. Outgoing txs by top sender, excluding the bad ones */
filtered_outgoing AS (
    SELECT
        t."value"                                          AS amt,
        t."receipt_gas_used" * t."gas_price"               AS fee
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN   top_sender  s ON t."from_address" = s.addr
    JOIN   cutoff      c ON t."block_timestamp" < c.ts
    WHERE  t."receipt_status" = 1
      AND  t."hash" NOT IN (SELECT "transaction_hash" FROM bad_tx)
),

/* 4. Incoming successful txs to the address */
filtered_incoming AS (
    SELECT t."value" AS amt
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN   top_sender  s ON t."to_address" = s.addr
    JOIN   cutoff      c ON t."block_timestamp" < c.ts
    WHERE  t."receipt_status" = 1
),

/* 5. Number of blocks mined by the address before cut-off */
miner_blocks AS (
    SELECT COUNT(*) AS mined_cnt
    FROM   CRYPTO.CRYPTO_ETHEREUM.BLOCKS b
    JOIN   top_sender  s ON b."miner" = s.addr
    JOIN   cutoff      c ON b."timestamp" < c.ts
)

/* 6. Assemble final balance (in Ether) */
SELECT
    s.addr AS "address",
    /* components in Wei */
    COALESCE((SELECT SUM(amt) FROM filtered_incoming),0)                     AS "incoming_wei",
    COALESCE((SELECT SUM(amt) FROM filtered_outgoing),0)                     AS "outgoing_wei",
    COALESCE((SELECT SUM(fee) FROM filtered_outgoing),0)                     AS "gas_paid_wei",
    COALESCE(m.mined_cnt,0) * 2000000000000000000                            AS "miner_rewards_wei",
    /* final balance converted to Ether */
    (
        COALESCE((SELECT SUM(amt) FROM filtered_incoming),0)
      + COALESCE(m.mined_cnt,0) * 2000000000000000000
      - COALESCE((SELECT SUM(amt) FROM filtered_outgoing),0)
      - COALESCE((SELECT SUM(fee) FROM filtered_outgoing),0)
    ) / 1000000000000000000::NUMBER                                          AS "final_balance_eth"
FROM top_sender s
CROSS JOIN miner_blocks m;