/* ---------------------------------------------------------------
   Comprehensive pre-2017 Ethereum address report  (Snowflake SQL)
   --------------------------------------------------------------- */
WITH
/* 1. Filtered call-traces (exclude delegate/callcode/staticcall) */
valid_traces AS (
    SELECT
        "block_timestamp",
        "from_address",
        "to_address",
        /* use the value as-is (already NUMBER); COALESCE guards NULLs */
        COALESCE("value", 0)                       AS value_wei,
        "gas_used"
    FROM  "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
    WHERE "trace_type" = 'call'
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND "block_timestamp" < 1483228800000000         -- 2017-01-01 (µs)
),

/* 2. Incoming trace aggregates */
in_traces AS (
    SELECT
        "to_address"                                  AS address,
        COUNT(*)                                      AS in_trace_count,
        COUNT(DISTINCT "from_address")                AS in_addr_count,
        COUNT_IF(value_wei > 0)                       AS in_transfer_count,
        AVG(CASE WHEN value_wei > 0 THEN value_wei END)  AS in_avg_amount_wei,
        AVG("gas_used")                               AS avg_gas_used,
        STDDEV_SAMP("gas_used")                       AS std_gas_used,
        SUM(value_wei)                                AS in_total_value
    FROM valid_traces
    GROUP BY "to_address"
),

/* 3. Outgoing trace aggregates */
out_traces AS (
    SELECT
        "from_address"                                AS address,
        COUNT(*)                                      AS out_trace_count,
        COUNT(DISTINCT "to_address")                  AS out_addr_count,
        COUNT_IF(value_wei > 0)                       AS out_transfer_count,
        AVG(CASE WHEN value_wei > 0 THEN value_wei END) AS out_avg_amount_wei,
        SUM(value_wei)                                AS out_total_value
    FROM valid_traces
    GROUP BY "from_address"
),

/* 4. Activity rhythm & active days (addresses with >24 activities) */
activity AS (
    SELECT
        addr                                          AS address,
        COUNT(*)                                      AS total_acts,
        COUNT(DISTINCT DATE_TRUNC('day',
                       TO_TIMESTAMP_NTZ(block_ts/1e6))) AS active_days,
        SUM(COS(2*PI()*hr/24))                        AS sum_cos,
        SUM(SIN(2*PI()*hr/24))                        AS sum_sin
    FROM (
        /* incoming & outgoing combined for activity */
        SELECT
            "block_timestamp"                         AS block_ts,
            MOD(FLOOR(("block_timestamp"/1000000)/3600),24) AS hr,
            "from_address"                            AS addr
        FROM valid_traces
        UNION ALL
        SELECT
            "block_timestamp",
            MOD(FLOOR(("block_timestamp"/1000000)/3600),24),
            "to_address"
        FROM valid_traces
    ) t
    GROUP BY addr
    HAVING COUNT(*) > 24
),
activity_final AS (
    SELECT
        address,
        SQRT(POWER(sum_cos,2) + POWER(sum_sin,2)) / total_acts AS R_active_hour,
        active_days
    FROM activity
),

/* 5. Mining rewards ------------------------------------------- */
rewards AS (
    SELECT
        "to_address"                    AS address,
        SUM(COALESCE("value",0))        AS reward_wei
    FROM  "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
    WHERE "trace_type" = 'reward'
      AND "block_timestamp" < 1483228800000000
    GROUP BY "to_address"
),

/* 6. Contract creations & byte-code length -------------------- */
contract_creations AS (
    SELECT
        "from_address"                  AS address,
        COUNT(*)                        AS contract_create_count
    FROM  "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
    WHERE "trace_type" = 'create'
      AND "block_timestamp" < 1483228800000000
    GROUP BY "from_address"
),
contract_bytecode AS (
    SELECT
        tc."from_address"               AS address,
        MAX(LENGTH(c."bytecode"))       AS bytecode_size
    FROM  "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"    tc
    JOIN  "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."CONTRACTS" c
          ON tc."to_address" = c."address"
    WHERE tc."trace_type" = 'create'
      AND tc."block_timestamp" < 1483228800000000
    GROUP BY tc."from_address"
),

/* 7. Failed transactions -------------------------------------- */
failures AS (
    SELECT
        "from_address"                  AS address,
        COUNT(*)                        AS failure_count
    FROM  "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRANSACTIONS"
    WHERE "receipt_status" = 0
      AND "block_timestamp" < 1483228800000000
    GROUP BY "from_address"
),

/* 8. Transaction fees (successful TX only) -------------------- */
tx_fees AS (
    SELECT
        "from_address"                                              AS address,
        SUM("receipt_gas_used" * "gas_price")                       AS fee_wei
    FROM  "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRANSACTIONS"
    WHERE "receipt_status" = 1
      AND "block_timestamp" < 1483228800000000
    GROUP BY "from_address"
),

/* 9. ERC-20 token transfer stats ------------------------------ */
token_in AS (
    SELECT
        "to_address"                        AS address,
        COUNT(*)                            AS token_in_tnx,
        COUNT(DISTINCT "token_address")     AS token_in_type,
        COUNT(DISTINCT "from_address")      AS token_from_addr
    FROM  "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS"
    WHERE "block_timestamp" < 1483228800000000
    GROUP BY "to_address"
),
token_out AS (
    SELECT
        "from_address"                      AS address,
        COUNT(*)                            AS token_out_tnx,
        COUNT(DISTINCT "token_address")     AS token_out_type,
        COUNT(DISTINCT "to_address")        AS token_to_addr
    FROM  "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS"
    WHERE "block_timestamp" < 1483228800000000
    GROUP BY "from_address"
),

/* 10. Master list of pre-2017 addresses ----------------------- */
addresses AS (
    SELECT address FROM in_traces
    UNION
    SELECT address FROM out_traces
    UNION
    SELECT address FROM activity_final
    UNION
    SELECT address FROM rewards
    UNION
    SELECT address FROM contract_creations
    UNION
    SELECT address FROM failures
    UNION
    SELECT address FROM token_in
    UNION
    SELECT address FROM token_out
)

/* --------------------------------------------------------------
   Final consolidated report
   -------------------------------------------------------------- */
SELECT
    a.address,

    /* Net balance (ETH) --------------------------------------- */
    (COALESCE(in_traces.in_total_value ,0)
     - COALESCE(out_traces.out_total_value,0)
     - COALESCE(tx_fees.fee_wei         ,0)) / 1e18      AS balance,

    /* Activity ------------------------------------------------ */
    activity_final.R_active_hour,
    activity_final.active_days,

    /* Incoming metrics --------------------------------------- */
    COALESCE(in_traces.in_trace_count     ,0)             AS in_trace_count,
    COALESCE(in_traces.in_addr_count      ,0)             AS in_addr_count,
    COALESCE(in_traces.in_transfer_count  ,0)             AS in_transfer_count,
    COALESCE(in_traces.in_avg_amount_wei  ,0)/1e18        AS in_avg_amount,
    COALESCE(in_traces.avg_gas_used       ,0)             AS avg_gas_used,
    COALESCE(in_traces.std_gas_used       ,0)             AS std_gas_used,

    /* Outgoing metrics --------------------------------------- */
    COALESCE(out_traces.out_trace_count   ,0)             AS out_trace_count,
    COALESCE(out_traces.out_addr_count    ,0)             AS out_addr_count,
    COALESCE(out_traces.out_transfer_count,0)             AS out_transfer_count,
    COALESCE(out_traces.out_avg_amount_wei,0)/1e18        AS out_avg_amount,

    /* Token statistics --------------------------------------- */
    COALESCE(token_in.token_in_tnx   ,0)                  AS token_in_tnx,
    COALESCE(token_in.token_in_type  ,0)                  AS token_in_type,
    COALESCE(token_in.token_from_addr,0)                  AS token_from_addr,
    COALESCE(token_out.token_out_tnx ,0)                  AS token_out_tnx,
    COALESCE(token_out.token_out_type,0)                  AS token_out_type,
    COALESCE(token_out.token_to_addr ,0)                  AS token_to_addr,

    /* Rewards / contracts / errors / code -------------------- */
    COALESCE(rewards.reward_wei                 ,0)/1e18  AS reward_amount,
    COALESCE(contract_creations.contract_create_count,0)  AS contract_create_count,
    COALESCE(failures.failure_count             ,0)       AS failure_count,
    COALESCE(contract_bytecode.bytecode_size    ,0)       AS bytecode_size
FROM   addresses                     a
LEFT   JOIN in_traces          ON a.address = in_traces.address
LEFT   JOIN out_traces         ON a.address = out_traces.address
LEFT   JOIN activity_final     ON a.address = activity_final.address
LEFT   JOIN tx_fees            ON a.address = tx_fees.address
LEFT   JOIN rewards            ON a.address = rewards.address
LEFT   JOIN contract_creations ON a.address = contract_creations.address
LEFT   JOIN failures           ON a.address = failures.address
LEFT   JOIN contract_bytecode  ON a.address = contract_bytecode.address
LEFT   JOIN token_in           ON a.address = token_in.address
LEFT   JOIN token_out          ON a.address = token_out.address;