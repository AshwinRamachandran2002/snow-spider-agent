WITH
/* 1 ─────────── successful basic CALL traces (exclude delegatecall/callcode/staticcall) */
base_traces AS (
    SELECT
        "from_address",
        "to_address",
        "value"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES"
    WHERE "trace_type" = 'call'
      AND "call_type"  = 'call'
      AND "status"     = 1
),

/* 2 ─────────── per-address deltas from those traces (+ for receiver, − for sender) */
trace_deltas AS (
    SELECT "to_address"   AS addr,  SUM("value")            AS delta_wei
    FROM   base_traces
    WHERE  "to_address" IS NOT NULL
    GROUP  BY "to_address"
    UNION ALL
    SELECT "from_address" AS addr, -SUM("value")            AS delta_wei
    FROM   base_traces
    WHERE  "from_address" IS NOT NULL
    GROUP  BY "from_address"
),
trace_net AS (
    SELECT addr, SUM(delta_wei) AS net_wei
    FROM   trace_deltas
    GROUP  BY addr
),

/* 3 ─────────── miner income = sum of gas fees per block */
fee_per_block AS (
    SELECT
        "block_number",
        SUM("gas_price" * "receipt_gas_used") AS miner_fee_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS"
    WHERE "receipt_gas_used" IS NOT NULL
    GROUP BY "block_number"
),
miner_income AS (
    SELECT
        b."miner"                   AS addr,
        SUM(f.miner_fee_wei)        AS net_wei
    FROM fee_per_block f
    JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."BLOCKS" b
      ON f."block_number" = b."number"
    WHERE b."miner" IS NOT NULL
    GROUP BY b."miner"
),

/* 4 ─────────── sender gas-fee cost (negative) */
sender_cost AS (
    SELECT
        tx."from_address"                                  AS addr,
       -SUM(tx."gas_price" * tx."receipt_gas_used")        AS net_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS" tx
    WHERE tx."receipt_gas_used" IS NOT NULL
      AND tx."from_address"    IS NOT NULL
    GROUP BY tx."from_address"
),

/* 5 ─────────── combine all events */
all_events AS (
    SELECT * FROM trace_net
    UNION ALL SELECT * FROM miner_income
    UNION ALL SELECT * FROM sender_cost
),
agg AS (
    SELECT
        addr,
        SUM(net_wei) AS total_net_wei
    FROM all_events
    WHERE addr IS NOT NULL
    GROUP BY addr
),

/* 6 ─────────── pick top-10 richest addresses */
top10 AS (
    SELECT total_net_wei
    FROM   agg
    ORDER  BY total_net_wei DESC NULLS LAST
    LIMIT  10
)

/* 7 ─────────── average balance in quadrillions (10^15 Wei), rounded */
SELECT
    ROUND(AVG(total_net_wei) / 1e15, 2)  AS avg_balance_quadrillions
FROM top10;