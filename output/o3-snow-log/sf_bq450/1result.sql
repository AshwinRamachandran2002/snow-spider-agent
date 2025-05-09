/* ====================================================================
   Comprehensive Ethereum-address report
   – activity strictly before 1 Jan 2017  (1483228800000000 µs)
   – Snowflake SQL   (fixed case-sensitive identifier issue)
   ==================================================================== */
WITH

/* ---------- 1. base transactions (successful only) ----------------- */
tx_pre2017 AS (
    SELECT
        "hash",
        "from_address",
        "to_address",
        "value",                      -- Wei
        "gas_price",                  -- Wei
        "receipt_gas_used",
        "block_timestamp"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "block_timestamp" < 1483228800000000        -- 2017-01-01
      AND "receipt_status" = 1                        -- success
),

/* ---------- 2. balance components ---------------------------------- */
incoming_tx AS (
    SELECT
        "to_address"                                         AS address,
        SUM("value")                                         AS incoming_value,
        COUNT(*)                                             AS incoming_tx_cnt
    FROM tx_pre2017
    WHERE "to_address" IS NOT NULL
    GROUP BY "to_address"
),
outgoing_tx AS (
    SELECT
        "from_address"                                       AS address,
        SUM("value")                                         AS outgoing_value,
        SUM("gas_price" * "receipt_gas_used")                AS outgoing_fees,
        COUNT(*)                                             AS outgoing_tx_cnt
    FROM tx_pre2017
    GROUP BY "from_address"
),
balance_cte AS (
    SELECT
        COALESCE(i.address, o.address)                                           AS address,
        COALESCE(i.incoming_value , 0)                                           AS incoming_value,
        COALESCE(o.outgoing_value , 0)                                           AS outgoing_value,
        COALESCE(o.outgoing_fees  , 0)                                           AS outgoing_fees,
        ( COALESCE(i.incoming_value ,0)
        - COALESCE(o.outgoing_value ,0)
        - COALESCE(o.outgoing_fees  ,0) ) / 1e18                                 AS balance  -- Ether
    FROM incoming_tx i
    FULL OUTER JOIN outgoing_tx o
      ON i.address = o.address
),

/* ---------- 3. generic activity set (sender + receiver) ------------ */
activity_tx AS (
    SELECT "to_address"   AS address, "block_timestamp" FROM tx_pre2017 WHERE "to_address" IS NOT NULL
    UNION ALL
    SELECT "from_address" AS address, "block_timestamp" FROM tx_pre2017
),

/* ---------- 4. active-day count ------------------------------------ */
activity_stats AS (
    SELECT
        address,
        COUNT(*)                                                                    AS total_activity,
        COUNT( DISTINCT DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6)) )  AS active_days
    FROM activity_tx
    GROUP BY address
),

/* ---------- 5. hourly-activity vectors ----------------------------- */
hourly AS (
    SELECT
        address,
        EXTRACT('hour', TO_TIMESTAMP("block_timestamp" / 1e6))       AS tx_hour,
        COUNT(*)                                                     AS cnt
    FROM activity_tx
    GROUP BY address, tx_hour
),
hourly_vec AS (
    SELECT
        address,
        SUM(cnt)                                                     AS n_tx,
        SUM(cnt * COS(2 * PI() * tx_hour / 24))                      AS sum_cos,
        SUM(cnt * SIN(2 * PI() * tx_hour / 24))                      AS sum_sin
    FROM hourly
    GROUP BY address
),
hour_metric AS (
    SELECT
        address,
        CASE WHEN n_tx > 24
             THEN SQRT( POWER(sum_cos / n_tx, 2) + POWER(sum_sin / n_tx, 2) )
             ELSE NULL
        END                                                          AS R_active_hour
    FROM hourly_vec
),

/* ---------- 6. traces (exclude delegate/static/callcode) ----------- */
traces_pre2017 AS (
    SELECT *
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "block_timestamp" < 1483228800000000
      AND ( "call_type" IS NULL OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
),

/* ---------- 7. incoming / outgoing trace metrics ------------------- */
incoming_trace AS (
    SELECT
        "to_address"                                                 AS address,
        COUNT(*)                                                     AS in_trace_count,
        COUNT( DISTINCT "from_address")                              AS in_addr_count,
        COUNT_IF("value" <> 0)                                       AS in_transfer_count,
        AVG( CASE WHEN "value" <> 0 THEN "value" END ) / 1e18        AS in_avg_amount,
        AVG( CASE WHEN "trace_type"='call' THEN "gas_used" END )     AS avg_gas_used,
        STDDEV( CASE WHEN "trace_type"='call' THEN "gas_used" END )  AS std_gas_used
    FROM traces_pre2017
    WHERE "to_address" IS NOT NULL
    GROUP BY "to_address"
),
outgoing_trace AS (
    SELECT
        "from_address"                                               AS address,
        COUNT(*)                                                     AS out_trace_count,
        COUNT( DISTINCT "to_address")                                AS out_addr_count,
        COUNT_IF("value" <> 0)                                       AS out_transfer_count,
        AVG( CASE WHEN "value" <> 0 THEN "value" END ) / 1e18        AS out_avg_amount
    FROM traces_pre2017
    GROUP BY "from_address"
),

/* ---------- 8. ERC-20 token transfers ------------------------------ */
token_pre2017 AS (
    SELECT *
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE "block_timestamp" < 1483228800000000
),
token_in AS (
    SELECT
        "to_address"                                 AS address,
        COUNT(*)                                     AS token_in_tnx,
        COUNT( DISTINCT "token_address")             AS token_in_type,
        COUNT( DISTINCT "from_address")              AS token_from_addr
    FROM token_pre2017
    GROUP BY "to_address"
),
token_out AS (
    SELECT
        "from_address"                               AS address,
        COUNT(*)                                     AS token_out_tnx,
        COUNT( DISTINCT "token_address")             AS token_out_type,
        COUNT( DISTINCT "to_address")                AS token_to_addr
    FROM token_pre2017
    GROUP BY "from_address"
),

/* ---------- 9. mining rewards -------------------------------------- */
reward_cte AS (
    SELECT
        "to_address"                 AS address,
        SUM("value") / 1e18          AS reward_amount     -- Ether
    FROM traces_pre2017
    WHERE "trace_type" = 'reward'
    GROUP BY "to_address"
),

/* ---------- 10. contract-creation count ---------------------------- */
contract_create AS (
    SELECT
        "from_address"               AS address,
        COUNT(*)                     AS contract_create_count
    FROM traces_pre2017
    WHERE "trace_type" = 'create'
    GROUP BY "from_address"
),

/* ---------- 11. failed traces (status = 0) ------------------------- */
failure_cte AS (
    SELECT
        "from_address"               AS address,
        COUNT(*)                     AS failure_count
    FROM traces_pre2017
    WHERE "status" = 0
    GROUP BY "from_address"
),

/* ---------- 12. contract byte-code sizes --------------------------- */
bytecode_cte AS (
    SELECT
        "address"           AS address,          -- <<< fixed: provide unquoted alias
        LENGTH("bytecode")  AS bytecode_size
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.CONTRACTS
    WHERE "block_timestamp" < 1483228800000000
),

/* ---------- 13. full address universe ------------------------------ */
all_addresses AS (
    SELECT address FROM balance_cte           UNION
    SELECT address FROM activity_stats        UNION
    SELECT address FROM incoming_trace        UNION
    SELECT address FROM outgoing_trace        UNION
    SELECT address FROM token_in              UNION
    SELECT address FROM token_out             UNION
    SELECT address FROM reward_cte            UNION
    SELECT address FROM contract_create       UNION
    SELECT address FROM failure_cte           UNION
    SELECT address FROM bytecode_cte
)

/* =================== FINAL REPORT ================================== */
SELECT
    a.address                                                         AS "address",

    /* ---- balance ---- */
    b.balance                                                         AS "balance",

    /* ---- activity metrics ---- */
    h.R_active_hour                                                   AS "R_active_hour",
    act.active_days                                                   AS "active_days",

    /* ---- incoming trace stats ---- */
    it.in_trace_count,  it.in_addr_count, it.in_transfer_count,
    it.in_avg_amount,   it.avg_gas_used, it.std_gas_used,

    /* ---- outgoing trace stats ---- */
    ot.out_trace_count, ot.out_addr_count, ot.out_transfer_count,
    ot.out_avg_amount,

    /* ---- token metrics ---- */
    tin.token_in_tnx,   tin.token_in_type,  tin.token_from_addr,
    tout.token_out_tnx, tout.token_out_type, tout.token_to_addr,

    /* ---- rewards & contracts ---- */
    rw.reward_amount,
    cc.contract_create_count,
    fl.failure_count,
    bc.bytecode_size

FROM all_addresses                           a

LEFT JOIN balance_cte        b   ON a.address = b.address
LEFT JOIN hour_metric        h   ON a.address = h.address
LEFT JOIN activity_stats     act ON a.address = act.address

LEFT JOIN incoming_trace     it  ON a.address = it.address
LEFT JOIN outgoing_trace     ot  ON a.address = ot.address

LEFT JOIN token_in           tin ON a.address = tin.address
LEFT JOIN token_out          tout ON a.address = tout.address

LEFT JOIN reward_cte         rw  ON a.address = rw.address
LEFT JOIN contract_create    cc  ON a.address = cc.address
LEFT JOIN failure_cte        fl  ON a.address = fl.address
LEFT JOIN bytecode_cte       bc  ON a.address = bc.address

ORDER BY b.balance DESC NULLS LAST;