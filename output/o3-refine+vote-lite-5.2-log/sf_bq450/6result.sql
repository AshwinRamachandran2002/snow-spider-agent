/* =======================================================================
   Comprehensive Ethereum address report (activity before 01‑Jan‑2017)
   ======================================================================= */
WITH
/* ---------- 1. Time cut‑off ------------------------------------------ */
cutoff AS (SELECT 1483228800000000::NUMBER AS ts_cutoff),   -- 2017‑01‑01 (µs)

/* ---------- 2. Successful CALL traces -------------------------------- */
traces AS (
    SELECT
        "block_timestamp",
        "block_number",
        COALESCE("from_address",'') AS from_addr,
        COALESCE("to_address"  ,'') AS to_addr,
        "gas_used"                 AS gas_used,
        "value"                    AS wei_val
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", cutoff
    WHERE "status" = 1
      AND "trace_type" = 'call'
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND "block_timestamp" < ts_cutoff
),

/* ---------- 3. ETH aggregates ---------------------------------------- */
eth_in AS (
    SELECT
        to_addr                                 AS address,
        COUNT(*)                                AS in_trace_count,
        COUNT(DISTINCT from_addr)               AS in_addr_count,
        COUNT_IF(wei_val <> 0)                  AS in_transfer_count,
        AVG(wei_val) / 1e18                     AS in_avg_amount,
        SUM(wei_val)                            AS in_wei_sum
    FROM traces
    WHERE to_addr <> ''
    GROUP BY to_addr
),
eth_out AS (
    SELECT
        from_addr                               AS address,
        COUNT(*)                                AS out_trace_count,
        COUNT(DISTINCT to_addr)                 AS out_addr_count,
        COUNT_IF(wei_val <> 0)                  AS out_transfer_count,
        AVG(wei_val) / 1e18                     AS out_avg_amount,
        SUM(wei_val)                            AS out_wei_sum
    FROM traces
    WHERE from_addr <> ''
    GROUP BY from_addr
),

/* ---------- 4. Gas stats (incoming) ---------------------------------- */
gas_stats AS (
    SELECT
        to_addr                                 AS address,
        AVG(gas_used)                           AS avg_gas_used,
        STDDEV_POP(gas_used)                    AS std_gas_used
    FROM traces
    WHERE to_addr <> ''
    GROUP BY to_addr
),

/* ---------- 5. Hourly consistency & active days ---------------------- */
activity AS (
    SELECT addr, ts,
           DATE_PART('hour', ts) AS hr
    FROM (
        SELECT from_addr AS addr,
               TO_TIMESTAMP("block_timestamp"/1e6) AS ts
        FROM traces WHERE from_addr <> ''
        UNION ALL
        SELECT to_addr,
               TO_TIMESTAMP("block_timestamp"/1e6)
        FROM traces WHERE to_addr <> ''
    )
),
hour_consistency AS (
    SELECT
        addr AS address,
        SQRT( POWER(SUM(COS(2*PI()*hr/24)),2) +
              POWER(SUM(SIN(2*PI()*hr/24)),2) ) / COUNT(*) AS R_active_hour
    FROM activity
    GROUP BY addr
),
active_days AS (
    SELECT
        addr AS address,
        COUNT(DISTINCT DATE_TRUNC('day', ts)) AS active_days
    FROM activity
    GROUP BY addr
),

/* ---------- 6. Transaction fees ------------------------------------- */
tx_fees AS (
    SELECT
        "from_address"                          AS address,
        SUM(COALESCE("receipt_gas_used",0) * COALESCE("gas_price",0)) AS fee_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS", cutoff
    WHERE "block_timestamp" < ts_cutoff
      AND "receipt_status" = 1
    GROUP BY "from_address"
),

/* ---------- 7. Rewards & contract creations ------------------------- */
rewards AS (
    SELECT "to_address" AS address,
           SUM("value") AS reward_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", cutoff
    WHERE "trace_type" = 'reward'
      AND "block_timestamp" < ts_cutoff
    GROUP BY "to_address"
),
contracts_created AS (
    SELECT "from_address" AS address,
           COUNT(*)       AS contract_create_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", cutoff
    WHERE "trace_type" = 'create'
      AND "block_timestamp" < ts_cutoff
    GROUP BY "from_address"
),

/* ---------- 8. Failed transactions ---------------------------------- */
failures AS (
    SELECT "from_address" AS address,
           COUNT(*)       AS failure_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS", cutoff
    WHERE "block_timestamp" < ts_cutoff
      AND COALESCE("receipt_status",0) = 0
    GROUP BY "from_address"
),

/* ---------- 9. Contract byte‑code size ------------------------------ */
bytecode AS (
    SELECT
        "address" AS address,                       -- ensure case‑insensitive alias
        (LENGTH("bytecode") - 2) / 2 AS bytecode_size
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."CONTRACTS", cutoff
    WHERE "block_timestamp" < ts_cutoff
),

/* ---------- 10. ERC‑20 token metrics -------------------------------- */
tok_in AS (
    SELECT "to_address"  AS address,
           COUNT(*)      AS token_in_tnx,
           COUNT(DISTINCT "token_address") AS token_in_type,
           COUNT(DISTINCT "from_address")  AS token_from_addr
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS", cutoff
    WHERE "block_timestamp" < ts_cutoff
    GROUP BY "to_address"
),
tok_out AS (
    SELECT "from_address" AS address,
           COUNT(*)       AS token_out_tnx,
           COUNT(DISTINCT "token_address") AS token_out_type,
           COUNT(DISTINCT "to_address")    AS token_to_addr
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS", cutoff
    WHERE "block_timestamp" < ts_cutoff
    GROUP BY "from_address"
),

/* ---------- 11. Address universe ------------------------------------ */
all_addr AS (
    SELECT address FROM eth_in
    UNION
    SELECT address FROM eth_out
    UNION
    SELECT address FROM tok_in
    UNION
    SELECT address FROM tok_out
    UNION
    SELECT address FROM rewards
    UNION
    SELECT address FROM bytecode
)

/* ---------- 12. Final report ---------------------------------------- */
SELECT
    a.address,

    /* Net balance (Ether) */
    (  COALESCE(ei.in_wei_sum ,0)
     - COALESCE(eo.out_wei_sum,0)
     - COALESCE(fee.fee_wei  ,0)
     + COALESCE(r.reward_wei ,0)
    ) / 1e18                                            AS balance,

    hc.R_active_hour,
    ad.active_days,

    /* Incoming ETH metrics */
    ei.in_trace_count,
    ei.in_addr_count,
    ei.in_transfer_count,
    ei.in_avg_amount,
    gs.avg_gas_used,
    gs.std_gas_used,

    /* Outgoing ETH metrics */
    eo.out_trace_count,
    eo.out_addr_count,
    eo.out_transfer_count,
    eo.out_avg_amount,

    /* Token metrics */
    ti.token_in_tnx,
    ti.token_in_type,
    ti.token_from_addr,
    to_.token_out_tnx,
    to_.token_out_type,
    to_.token_to_addr,

    /* Rewards & contract creations */
    COALESCE(r.reward_wei,0) / 1e18                     AS reward_amount,
    cc.contract_create_count,

    /* Failures & byte‑code size */
    f.failure_count,
    bc.bytecode_size

FROM all_addr              AS a
LEFT JOIN eth_in           AS ei  ON a.address = ei.address
LEFT JOIN eth_out          AS eo  ON a.address = eo.address
LEFT JOIN tx_fees          AS fee ON a.address = fee.address
LEFT JOIN rewards          AS r   ON a.address = r.address
LEFT JOIN contracts_created AS cc ON a.address = cc.address
LEFT JOIN failures         AS f   ON a.address = f.address
LEFT JOIN bytecode         AS bc  ON a.address = bc.address
LEFT JOIN tok_in           AS ti  ON a.address = ti.address
LEFT JOIN tok_out          AS to_ ON a.address = to_.address
LEFT JOIN gas_stats        AS gs  ON a.address = gs.address
LEFT JOIN hour_consistency AS hc  ON a.address = hc.address
LEFT JOIN active_days      AS ad  ON a.address = ad.address

/* Exclude addresses without any activity */
WHERE COALESCE(ei.in_trace_count,
               eo.out_trace_count,
               ti.token_in_tnx,
               to_.token_out_tnx,
               r.reward_wei,
               cc.contract_create_count,
               bc.bytecode_size) IS NOT NULL;