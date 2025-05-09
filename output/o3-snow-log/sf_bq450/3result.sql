/* ---------------------------------------------------------
   Comprehensive address-level report for all Ethereum
   addresses active BEFORE 1-Jan-2017 (UTC)
   (cut-off 1483228800000000 µs)
----------------------------------------------------------*/
WITH
/* ---- universal cut-off ----------------------------------------------- */
const AS (
    SELECT 1483228800000000 AS cutoff_ts
),

/* ---- TRACES (exclude delegatecall / callcode / staticcall) ------------ */
trace_filtered AS (
    SELECT  "from_address",
            "to_address",
            "value",
            "gas",
            "gas_used",
            "call_type",
            "trace_type",
            "status",
            "block_timestamp",
            "block_number"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", const
    WHERE   "block_timestamp" < cutoff_ts
      AND  ( "call_type" IS NULL
             OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
),

/* ---- activity pattern (hour-of-day uniformity & active days) ---------- */
activity AS (
    SELECT  addr,
            COUNT(*)                             AS total_traces,
            SUM( COS( 2*PI()*hour/24 ) )         AS sum_cos,
            SUM( SIN( 2*PI()*hour/24 ) )         AS sum_sin,
            COUNT(DISTINCT activity_day)         AS active_days
    FROM (
        /* from side */
        SELECT  "from_address" AS addr,
                DATE_PART('hour', TO_TIMESTAMP("block_timestamp"/1000000)) AS hour,
                TO_DATE(TO_TIMESTAMP("block_timestamp"/1000000))           AS activity_day
        FROM    trace_filtered
        UNION ALL
        /* to side */
        SELECT  "to_address" AS addr,
                DATE_PART('hour', TO_TIMESTAMP("block_timestamp"/1000000)) AS hour,
                TO_DATE(TO_TIMESTAMP("block_timestamp"/1000000))           AS activity_day
        FROM    trace_filtered
    )
    GROUP BY addr
),
activity_stats AS (
    SELECT  addr,
            CASE WHEN total_traces > 0
                 THEN SQRT( sum_cos*sum_cos + sum_sin*sum_sin ) / total_traces
            END                                   AS R_active_hour,
            active_days
    FROM    activity
),

/* ---- successful external TRANSACTIONS --------------------------------- */
tx_success AS (
    SELECT  "hash",
            "from_address",
            "to_address",
            "value",
            "gas_price",
            "receipt_gas_used",
            "block_timestamp"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS", const
    WHERE   "block_timestamp" < cutoff_ts
      AND   "receipt_status" = 1
),

/* ---- outgoing metrics ------------------------------------------------- */
outgoing_tx AS (
    SELECT  "from_address"                                AS addr,
            SUM("value")                                  AS out_value_wei,
            SUM("receipt_gas_used" * "gas_price")         AS out_fees_wei,
            COUNT(*)                                      AS out_trace_count,
            COUNT(DISTINCT "to_address")                  AS out_addr_count,
            SUM(CASE WHEN "value" > 0 THEN 1 ELSE 0 END)  AS out_transfer_count,
            AVG(CASE WHEN "value" > 0
                     THEN "value"/1e18 END)               AS out_avg_amount_eth
    FROM    tx_success
    GROUP   BY addr
),

/* ---- incoming metrics ------------------------------------------------- */
incoming_tx AS (
    SELECT  "to_address"                                  AS addr,
            SUM("value")                                  AS in_value_wei,
            COUNT(*)                                      AS in_trace_count,
            COUNT(DISTINCT "from_address")                AS in_addr_count,
            SUM(CASE WHEN "value" > 0 THEN 1 ELSE 0 END)  AS in_transfer_count,
            AVG(CASE WHEN "value" > 0
                     THEN "value"/1e18 END)               AS in_avg_amount_eth,
            AVG("receipt_gas_used")                       AS avg_gas_used,
            STDDEV("receipt_gas_used")                    AS std_gas_used
    FROM    tx_success
    GROUP   BY addr
),

/* ---- balance (Wei) ---------------------------------------------------- */
balance_calc AS (
    SELECT  a.addr,
            COALESCE(in_value_wei ,0)
          - COALESCE(out_value_wei,0)
          - COALESCE(out_fees_wei ,0)            AS balance_wei
    FROM (
        SELECT addr FROM incoming_tx
        UNION
        SELECT addr FROM outgoing_tx
    ) a
    LEFT JOIN incoming_tx USING(addr)
    LEFT JOIN outgoing_tx USING(addr)
),

/* ---- TOKEN TRANSFERS -------------------------------------------------- */
token_tx AS (
    SELECT  "from_address",
            "to_address",
            "token_address",
            "block_timestamp"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS", const
    WHERE   "block_timestamp" < cutoff_ts
),
token_in AS (
    SELECT  "to_address"                    AS addr,
            COUNT(*)                        AS token_in_tnx,
            COUNT(DISTINCT "token_address") AS token_in_type,
            COUNT(DISTINCT "from_address")  AS token_from_addr
    FROM    token_tx
    GROUP   BY addr
),
token_out AS (
    SELECT  "from_address"                  AS addr,
            COUNT(*)                        AS token_out_tnx,
            COUNT(DISTINCT "token_address") AS token_out_type,
            COUNT(DISTINCT "to_address")    AS token_to_addr
    FROM    token_tx
    GROUP   BY addr
),

/* ---- mining rewards --------------------------------------------------- */
rewards AS (
    SELECT  "to_address" AS addr,
            SUM("value") AS reward_wei
    FROM    trace_filtered
    WHERE   "trace_type" = 'reward'
    GROUP   BY addr
),

/* ---- contract creations ---------------------------------------------- */
contracts_made AS (
    SELECT  "from_address" AS addr,
            COUNT(*)       AS contract_create_count
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS", const
    WHERE   "block_timestamp" < cutoff_ts
      AND   "receipt_contract_address" IS NOT NULL
    GROUP   BY addr
),

/* ---- failed transactions --------------------------------------------- */
failures AS (
    SELECT  "from_address" AS addr,
            COUNT(*)       AS failure_count
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS", const
    WHERE   "block_timestamp" < cutoff_ts
      AND   "receipt_status" = 0
    GROUP   BY addr
),

/* ---- contract bytecode size ------------------------------------------ */
bytecode_sizes AS (
    SELECT  "address"                 AS addr,
            AVG(LENGTH("bytecode"))   AS bytecode_size
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."CONTRACTS", const
    WHERE   "block_timestamp" < cutoff_ts
    GROUP   BY addr
),

/* ---- master address list --------------------------------------------- */
all_addresses AS (
    SELECT addr FROM activity_stats
    UNION SELECT addr FROM incoming_tx
    UNION SELECT addr FROM outgoing_tx
    UNION SELECT addr FROM token_in
    UNION SELECT addr FROM token_out
    UNION SELECT addr FROM rewards
    UNION SELECT addr FROM contracts_made
    UNION SELECT addr FROM failures
    UNION SELECT addr FROM bytecode_sizes
)

/* =======================  FINAL REPORT ================================ */
SELECT
       a.addr                                   AS "address",

       ROUND(b.balance_wei / 1e18 , 4)          AS "balance",

       act.R_active_hour                        AS "R_active_hour",
       act.active_days                          AS "active_days",

       inc.in_trace_count                       AS "in_trace_count",
       inc.in_addr_count                        AS "in_addr_count",
       inc.in_transfer_count                    AS "in_transfer_count",
       ROUND(inc.in_avg_amount_eth ,4)          AS "in_avg_amount",
       inc.avg_gas_used                         AS "avg_gas_used",
       inc.std_gas_used                         AS "std_gas_used",

       out.out_trace_count                      AS "out_trace_count",
       out.out_addr_count                       AS "out_addr_count",
       out.out_transfer_count                   AS "out_transfer_count",
       ROUND(out.out_avg_amount_eth ,4)         AS "out_avg_amount",

       tin.token_in_tnx                         AS "token_in_tnx",
       tin.token_in_type                        AS "token_in_type",
       tin.token_from_addr                      AS "token_from_addr",

       tout.token_out_tnx                       AS "token_out_tnx",
       tout.token_out_type                      AS "token_out_type",
       tout.token_to_addr                       AS "token_to_addr",

       ROUND(rew.reward_wei / 1e18 ,4)          AS "reward_amount",
       cm.contract_create_count                 AS "contract_create_count",
       fl.failure_count                         AS "failure_count",
       bc.bytecode_size                         AS "bytecode_size"

FROM   all_addresses           a
LEFT   JOIN balance_calc    b  ON a.addr = b.addr
LEFT   JOIN activity_stats  act ON a.addr = act.addr
LEFT   JOIN incoming_tx     inc ON a.addr = inc.addr
LEFT   JOIN outgoing_tx     out ON a.addr = out.addr
LEFT   JOIN token_in        tin ON a.addr = tin.addr
LEFT   JOIN token_out       tout ON a.addr = tout.addr
LEFT   JOIN rewards         rew ON a.addr = rew.addr
LEFT   JOIN contracts_made  cm  ON a.addr = cm.addr
LEFT   JOIN failures        fl  ON a.addr = fl.addr
LEFT   JOIN bytecode_sizes  bc  ON a.addr = bc.addr

ORDER  BY "balance" DESC NULLS LAST;