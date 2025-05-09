/* -----------------------------------------------------------
   Comprehensive address-level report for all entities that
   were active BEFORE 1-Jan-2017 (UTC) on the Ethereum chain
   ----------------------------------------------------------- */
WITH
/* ---------- constants ----------------------------------------- */
vars AS (
    SELECT
        1483228800000000       AS cutoff_us,     -- 2017-01-01 in µs
        1000000                AS us_per_s,
        1e18::FLOAT            AS wei_per_eth
),

/* ---------- successful traces (exclude delegate/static/etc.) --- */
succ_traces AS (
    SELECT
        "from_address",
        "to_address",
        CAST("value" AS FLOAT)                 AS val_wei,
        "gas_used"                             AS gas_used_val,
        COALESCE("call_type",'call')           AS ctype,
        "block_timestamp"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES, vars
    WHERE "status" = 1
      AND COALESCE("call_type",'call')
            NOT IN ('delegatecall','callcode','staticcall')
      AND "block_timestamp" < vars.cutoff_us
),

/* ---------- incoming / outgoing ETH metrics ------------------- */
in_traces AS (
    SELECT
        "to_address"                              AS address,
        COUNT(*)                                  AS in_trace_count,
        COUNT(DISTINCT "from_address")            AS in_addr_count,
        COUNT_IF(val_wei <> 0)                    AS in_transfer_count,
        AVG(NULLIF(val_wei,0))                    AS in_avg_wei,
        SUM(val_wei)                              AS in_val_total_wei,
        AVG(CASE WHEN ctype = 'call' THEN gas_used_val END)        AS avg_gas_used,
        STDDEV_POP(CASE WHEN ctype = 'call' THEN gas_used_val END) AS std_gas_used
    FROM succ_traces
    GROUP BY 1
),

out_traces AS (
    SELECT
        "from_address"                            AS address,
        COUNT(*)                                  AS out_trace_count,
        COUNT(DISTINCT "to_address")              AS out_addr_count,
        COUNT_IF(val_wei <> 0)                    AS out_transfer_count,
        AVG(NULLIF(val_wei,0))                    AS out_avg_wei,
        SUM(val_wei)                              AS out_val_total_wei
    FROM succ_traces
    GROUP BY 1
),

/* ---------- hourly rhythm & active days ----------------------- */
act_stats AS (
    SELECT
        addr                                      AS address,
        COUNT(*)                                  AS total_act,
        CAST(
            SQRT(POWER(SUM(COS(2*PI()*hr/24)),2) +
                 POWER(SUM(SIN(2*PI()*hr/24)),2))
            / COUNT(*)  AS FLOAT)                AS r_active_hour,
        COUNT(DISTINCT CAST(ts_ntz AS DATE))      AS active_days
    FROM (
        /* outgoing */
        SELECT
            "from_address"  AS addr,
            TO_TIMESTAMP_NTZ("block_timestamp"/vars.us_per_s)                      AS ts_ntz,
            EXTRACT(HOUR FROM TO_TIMESTAMP_NTZ("block_timestamp"/vars.us_per_s))   AS hr
        FROM succ_traces, vars
        UNION ALL
        /* incoming */
        SELECT
            "to_address",
            TO_TIMESTAMP_NTZ("block_timestamp"/vars.us_per_s),
            EXTRACT(HOUR FROM TO_TIMESTAMP_NTZ("block_timestamp"/vars.us_per_s))
        FROM succ_traces, vars
    ) sub
    GROUP BY 1
    HAVING COUNT(*) > 24
),

/* ---------- token transfers before 2017 ----------------------- */
tok_pre17 AS (
    SELECT *
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS, vars
    WHERE "block_timestamp" < vars.cutoff_us
),

tok_in AS (
    SELECT
        "to_address"                     AS address,
        COUNT(*)                         AS token_in_tnx,
        COUNT(DISTINCT "token_address")  AS token_in_type,
        COUNT(DISTINCT "from_address")   AS token_from_addr
    FROM tok_pre17
    GROUP BY 1
),

tok_out AS (
    SELECT
        "from_address"                   AS address,
        COUNT(*)                         AS token_out_tnx,
        COUNT(DISTINCT "token_address")  AS token_out_type,
        COUNT(DISTINCT "to_address")     AS token_to_addr
    FROM tok_pre17
    GROUP BY 1
),

/* ---------- mining rewards ------------------------------------ */
rewards AS (
    SELECT
        "to_address"                     AS address,
        SUM(CAST("value" AS FLOAT))      AS reward_wei_total
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES, vars
    WHERE "trace_type" = 'reward'
      AND "block_timestamp" < vars.cutoff_us
    GROUP BY 1
),

/* ---------- contract creations -------------------------------- */
contracts_created AS (
    SELECT
        "from_address"                   AS address,
        COUNT(*)                         AS contract_create_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES, vars
    WHERE "trace_type" = 'create'
      AND "block_timestamp" < vars.cutoff_us
    GROUP BY 1
),

/* ---------- failed transactions ------------------------------- */
fail_tx AS (
    SELECT
        "from_address"                   AS address,
        COUNT(*)                         AS failure_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS, vars
    WHERE "receipt_status" = 0
      AND "block_timestamp" < vars.cutoff_us
    GROUP BY 1
),

/* ---------- tx-fees (successful txs) -------------------------- */
tx_fees AS (
    SELECT
        "from_address"                   AS address,
        SUM(CAST("gas_price" AS FLOAT) * CAST("receipt_gas_used" AS FLOAT)) AS fee_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS, vars
    WHERE "receipt_status" = 1
      AND "block_timestamp" < vars.cutoff_us
    GROUP BY 1
),

/* ---------- byte-code length for contracts -------------------- */
bytecode_len AS (
    SELECT
        "address"                        AS address,
        LENGTH("bytecode")               AS bytecode_size
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.CONTRACTS, vars
    WHERE "block_timestamp" < vars.cutoff_us
),

/* ---------- union of every address with any activity ---------- */
all_addr AS (
    SELECT address FROM in_traces
    UNION
    SELECT address FROM out_traces
    UNION
    SELECT address FROM tok_in
    UNION
    SELECT address FROM tok_out
    UNION
    SELECT address FROM rewards
    UNION
    SELECT address FROM contracts_created
    UNION
    SELECT address FROM fail_tx
    UNION
    SELECT address FROM bytecode_len
)

/* =================  FINAL REPORT  ============================= */
SELECT
    a.address,

    /* balance (ETH) */
    (COALESCE(it.in_val_total_wei ,0)
     - COALESCE(ot.out_val_total_wei,0)
     - COALESCE(fee.fee_wei ,0)) / vars.wei_per_eth                 AS balance,

    /* activity */
    act.r_active_hour,
    act.active_days,

    /* incoming metrics */
    it.in_trace_count,
    it.in_addr_count,
    it.in_transfer_count,
    it.in_avg_wei   / vars.wei_per_eth                              AS in_avg_amount,
    it.avg_gas_used,
    it.std_gas_used,

    /* outgoing metrics */
    ot.out_trace_count,
    ot.out_addr_count,
    ot.out_transfer_count,
    ot.out_avg_wei  / vars.wei_per_eth                              AS out_avg_amount,

    /* token metrics */
    ti.token_in_tnx,
    ti.token_in_type,
    ti.token_from_addr,
    to2.token_out_tnx,
    to2.token_out_type,
    to2.token_to_addr,

    /* rewards / contracts / failures / bytecode */
    rw.reward_wei_total / vars.wei_per_eth                          AS reward_amount,
    cc.contract_create_count,
    ft.failure_count,
    bc.bytecode_size

FROM all_addr               AS a
LEFT JOIN in_traces         AS it   ON a.address = it.address
LEFT JOIN out_traces        AS ot   ON a.address = ot.address
LEFT JOIN act_stats         AS act  ON a.address = act.address
LEFT JOIN tok_in            AS ti   ON a.address = ti.address
LEFT JOIN tok_out           AS to2  ON a.address = to2.address
LEFT JOIN rewards           AS rw   ON a.address = rw.address
LEFT JOIN contracts_created AS cc   ON a.address = cc.address
LEFT JOIN fail_tx           AS ft   ON a.address = ft.address
LEFT JOIN bytecode_len      AS bc   ON a.address = bc.address
LEFT JOIN tx_fees           AS fee  ON a.address = fee.address
LEFT JOIN vars              ON TRUE;