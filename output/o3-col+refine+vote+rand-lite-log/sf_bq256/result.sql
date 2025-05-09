WITH
    -- Timestamp for 2021-09-01 00:00:00 UTC (micro-seconds)
    cutoff AS (
        SELECT 1630454400000000 AS "ts"
    ),

    /* 1) All successful transactions before the cutoff */
    successful_tx AS (
        SELECT
            "from_address",
            "hash"
        FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS, cutoff
        WHERE "block_timestamp" < "ts"
          AND "receipt_status" = 1
    ),

    /* 2) Address with the most successful transactions */
    top_sender AS (
        SELECT "from_address"
        FROM successful_tx
        GROUP BY "from_address"
        ORDER BY COUNT(*) DESC NULLS LAST
        LIMIT 1
    ),

    /* 3) Transactions that must be excluded (contain delegatecall / callcode / staticcall) */
    excluded_tx AS (
        SELECT DISTINCT "transaction_hash"
        FROM CRYPTO.CRYPTO_ETHEREUM.TRACES, cutoff
        WHERE "block_timestamp" < "ts"
          AND LOWER(COALESCE("call_type", '')) IN ('delegatecall','callcode','staticcall')
    ),

    /* 4) Outgoing native ETH from non-excluded, successful txs of the top sender */
    outgoing AS (
        SELECT
            COALESCE(SUM("value"), 0) AS "val_out_wei"
        FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t
        JOIN top_sender                               s  ON t."from_address" = s."from_address"
        JOIN cutoff                                   c  ON 1 = 1
        WHERE t."block_timestamp" < c."ts"
          AND t."receipt_status" = 1
          AND t."hash" NOT IN (SELECT "transaction_hash" FROM excluded_tx)
    ),

    /* 5) Gas fees paid (gas_used × effective_gas_price) in the same valid txs */
    gas_paid AS (
        SELECT
            COALESCE(
                SUM(t."receipt_gas_used" * COALESCE(t."receipt_effective_gas_price", t."gas_price")),
                0
            ) AS "gas_paid_wei"
        FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t
        JOIN top_sender                               s  ON t."from_address" = s."from_address"
        JOIN cutoff                                   c  ON 1 = 1
        WHERE t."block_timestamp" < c."ts"
          AND t."receipt_status" = 1
          AND t."hash" NOT IN (SELECT "transaction_hash" FROM excluded_tx)
    ),

    /* 6) Incoming native ETH via direct transfers */
    incoming AS (
        SELECT
            COALESCE(SUM("value"), 0) AS "val_in_wei"
        FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t
        JOIN top_sender                               s  ON t."to_address" = s."from_address"
        JOIN cutoff                                   c  ON 1 = 1
        WHERE t."block_timestamp" < c."ts"
    ),

    /* 7) Miner / uncle rewards received */
    rewards AS (
        SELECT
            COALESCE(SUM("value"), 0) AS "rewards_wei"
        FROM CRYPTO.CRYPTO_ETHEREUM.TRACES  tr
        JOIN top_sender                         s   ON tr."to_address" = s."from_address"
        JOIN cutoff                             c   ON 1 = 1
        WHERE tr."block_timestamp" < c."ts"
          AND tr."trace_type" = 'reward'
    )

/* 8) Final balance calculation in Ether */
SELECT
    ( "val_in_wei"
    + "rewards_wei"
    - "val_out_wei"
    - "gas_paid_wei") / 1e18    AS "final_balance_eth"
FROM outgoing, gas_paid, incoming, rewards;