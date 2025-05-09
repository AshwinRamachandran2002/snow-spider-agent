WITH
/* -------------------------------------------------
   global constants
--------------------------------------------------*/
constants AS (
    SELECT 1483228800000000::NUMBER AS cutoff_ts ,   -- 2017-01-01 in µs
           1e18::FLOAT              AS wei_factor
),

/* -------------------------------------------------
   source filters (data before 2017-01-01)
--------------------------------------------------*/
traces_filtered AS (
    SELECT *
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES t , constants c
    WHERE t."block_timestamp" < c.cutoff_ts
),
transactions_filtered AS (
    SELECT *
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS tx , constants c
    WHERE tx."block_timestamp" < c.cutoff_ts
),
token_transfers_filtered AS (
    SELECT *
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS tt , constants c
    WHERE tt."block_timestamp" < c.cutoff_ts
),

/* -------------------------------------------------
   activity statistics (transactions & traces)
--------------------------------------------------*/
activity_events AS (
          /* tx – outgoing */
    SELECT "from_address" AS address , "block_timestamp"
    FROM   transactions_filtered
    WHERE  "from_address" IS NOT NULL
    UNION ALL
          /* tx – incoming */
    SELECT "to_address"   AS address , "block_timestamp"
    FROM   transactions_filtered
    WHERE  "to_address"   IS NOT NULL
    UNION ALL
          /* trace – outgoing */
    SELECT "from_address" AS address , "block_timestamp"
    FROM   traces_filtered
    WHERE  "from_address" IS NOT NULL
    UNION ALL
          /* trace – incoming */
    SELECT "to_address"   AS address , "block_timestamp"
    FROM   traces_filtered
    WHERE  "to_address"   IS NOT NULL
),
activity_stats AS (
    SELECT
        address,
        COUNT(*) AS activity_cnt,
        COUNT( DISTINCT DATE_TRUNC('day', TO_TIMESTAMP_NTZ("block_timestamp"/1000000)) ) AS active_days,
        SUM( COS( 2 * PI() * DATE_PART('hour', TO_TIMESTAMP_NTZ("block_timestamp"/1000000)) / 24 ) ) AS sum_cos,
        SUM( SIN( 2 * PI() * DATE_PART('hour', TO_TIMESTAMP_NTZ("block_timestamp"/1000000)) / 24 ) ) AS sum_sin
    FROM activity_events
    GROUP BY address
),
activity_final AS (
    SELECT
        address,
        active_days,
        CASE
            WHEN activity_cnt > 24
            THEN SQRT( POWER(sum_cos,2) + POWER(sum_sin,2) ) / activity_cnt
            ELSE NULL
        END AS R_active_hour
    FROM activity_stats
),

/* -------------------------------------------------
   successful ETH call traces (exclude delegate etc.)
--------------------------------------------------*/
call_traces AS (
    SELECT *
    FROM   traces_filtered
    WHERE  "trace_type" = 'call'
      AND  "status"     = 1
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
),

/* ---------------- incoming ETH ------------------*/
in_eth AS (
    SELECT
        "to_address"                            AS address,
        COUNT(*)                                AS in_trace_count,
        COUNT(DISTINCT "from_address")          AS in_addr_count,
        SUM( CASE WHEN "value" <> 0 THEN 1 ELSE 0 END )            AS in_transfer_count,
        AVG("value")                            AS in_avg_value_wei,
        AVG("gas_used")                         AS avg_gas_used,
        STDDEV_SAMP("gas_used")                 AS std_gas_used,
        SUM("value")                            AS in_value_wei
    FROM   call_traces
    WHERE  "to_address" IS NOT NULL
    GROUP BY "to_address"
),

/* ---------------- outgoing ETH ------------------*/
out_eth AS (
    SELECT
        "from_address"                          AS address,
        COUNT(*)                                AS out_trace_count,
        COUNT(DISTINCT "to_address")            AS out_addr_count,
        SUM( CASE WHEN "value" <> 0 THEN 1 ELSE 0 END )            AS out_transfer_count,
        AVG("value")                            AS out_avg_value_wei,
        SUM("value")                            AS out_value_wei
    FROM   call_traces
    WHERE  "from_address" IS NOT NULL
    GROUP BY "from_address"
),

/* ---------------- transaction fees --------------*/
tx_fees AS (
    SELECT
        "from_address"                          AS address,
        SUM("gas_price" * "receipt_gas_used")   AS fee_wei
    FROM   transactions_filtered
    WHERE  "receipt_status" = 1
      AND  "from_address"   IS NOT NULL
    GROUP BY "from_address"
),

/* ---------------- token metrics -----------------*/
token_in AS (
    SELECT
        "to_address"                            AS address,
        COUNT(*)                                AS token_in_tnx,
        COUNT(DISTINCT "token_address")         AS token_in_type,
        COUNT(DISTINCT "from_address")          AS token_from_addr
    FROM   token_transfers_filtered
    WHERE  "to_address" IS NOT NULL
    GROUP BY "to_address"
),
token_out AS (
    SELECT
        "from_address"                          AS address,
        COUNT(*)                                AS token_out_tnx,
        COUNT(DISTINCT "token_address")         AS token_out_type,
        COUNT(DISTINCT "to_address")            AS token_to_addr
    FROM   token_transfers_filtered
    WHERE  "from_address" IS NOT NULL
    GROUP BY "from_address"
),

/* ---------------- mining rewards ----------------*/
rewards AS (
    SELECT
        "to_address"             AS address,
        SUM("value")             AS reward_wei
    FROM   traces_filtered
    WHERE  "trace_type" = 'reward'
      AND  "to_address" IS NOT NULL
    GROUP BY "to_address"
),

/* ---------------- contracts created -------------*/
contracts_created AS (
    SELECT
        "from_address"           AS address,
        COUNT(*)                 AS contract_create_count
    FROM   traces_filtered
    WHERE  "trace_type" = 'create'
      AND  "from_address" IS NOT NULL
    GROUP BY "from_address"
),

/* ---------------- failed txs --------------------*/
failures AS (
    SELECT
        "from_address"           AS address,
        COUNT(*)                 AS failure_count
    FROM   transactions_filtered
    WHERE  "receipt_status" = 0
      AND  "from_address"  IS NOT NULL
    GROUP BY "from_address"
),

/* ---------------- bytecode size -----------------*/
bytecodes AS (
    SELECT
        "address",
        LENGTH("bytecode")       AS bytecode_size
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.CONTRACTS c , constants
    WHERE  c."block_timestamp" < constants.cutoff_ts
),
bytecode_agg AS (
    SELECT
        "address"  AS address,          -- unquoted alias for case-insensitive use
        MAX(bytecode_size) AS bytecode_size
    FROM   bytecodes
    GROUP BY "address"
),

/* -------------------------------------------------
   address universe (appears anywhere)
--------------------------------------------------*/
all_addresses AS (
    SELECT address FROM activity_stats
    UNION
    SELECT address FROM in_eth
    UNION
    SELECT address FROM out_eth
    UNION
    SELECT address FROM token_in
    UNION
    SELECT address FROM token_out
    UNION
    SELECT address FROM rewards
    UNION
    SELECT address FROM contracts_created
),

/* -------------------------------------------------
   final assembly
--------------------------------------------------*/
final AS (
    SELECT
        a.address,
        /* -------- net balance (ETH) ------------*/
        ROUND( ( COALESCE(in_eth.in_value_wei ,0)
               - COALESCE(out_eth.out_value_wei,0)
               - COALESCE(tx_fees.fee_wei      ,0)
               ) / c.wei_factor , 4 )                     AS balance,

        /* -------- activity metrics -------------*/
        af.R_active_hour,
        af.active_days,

        /* -------- incoming ETH -----------------*/
        COALESCE(in_eth.in_trace_count    ,0)             AS in_trace_count,
        COALESCE(in_eth.in_addr_count     ,0)             AS in_addr_count,
        COALESCE(in_eth.in_transfer_count ,0)             AS in_transfer_count,
        ROUND( COALESCE(in_eth.in_avg_value_wei ,0) / c.wei_factor , 4) AS in_avg_amount,
        COALESCE(in_eth.avg_gas_used      ,0)             AS avg_gas_used,
        COALESCE(in_eth.std_gas_used      ,0)             AS std_gas_used,

        /* -------- outgoing ETH -----------------*/
        COALESCE(out_eth.out_trace_count  ,0)             AS out_trace_count,
        COALESCE(out_eth.out_addr_count   ,0)             AS out_addr_count,
        COALESCE(out_eth.out_transfer_count,0)            AS out_transfer_count,
        ROUND( COALESCE(out_eth.out_avg_value_wei,0) / c.wei_factor , 4) AS out_avg_amount,

        /* -------- token transfers --------------*/
        COALESCE(ti.token_in_tnx   ,0)                    AS token_in_tnx,
        COALESCE(ti.token_in_type  ,0)                    AS token_in_type,
        COALESCE(ti.token_from_addr,0)                    AS token_from_addr,
        COALESCE(tox.token_out_tnx ,0)                    AS token_out_tnx,
        COALESCE(tox.token_out_type,0)                    AS token_out_type,
        COALESCE(tox.token_to_addr ,0)                    AS token_to_addr,

        /* -------- rewards / contracts / errors -*/
        ROUND( COALESCE(r.reward_wei,0) / c.wei_factor ,4)         AS reward_amount,
        COALESCE(cc.contract_create_count,0)                       AS contract_create_count,
        COALESCE(f.failure_count,0)                                AS failure_count,
        COALESCE(b.bytecode_size,0)                                AS bytecode_size
    FROM   all_addresses      a
    CROSS  JOIN constants     c
    LEFT   JOIN activity_final     af  ON af.address = a.address
    LEFT   JOIN in_eth             ON in_eth.address = a.address
    LEFT   JOIN out_eth            ON out_eth.address = a.address
    LEFT   JOIN tx_fees            ON tx_fees.address = a.address
    LEFT   JOIN token_in      ti   ON ti.address      = a.address
    LEFT   JOIN token_out     tox  ON tox.address     = a.address
    LEFT   JOIN rewards        r   ON r.address       = a.address
    LEFT   JOIN contracts_created cc ON cc.address    = a.address
    LEFT   JOIN failures       f   ON f.address       = a.address
    LEFT   JOIN bytecode_agg   b   ON b.address       = a.address
)

SELECT *
FROM   final
ORDER BY balance DESC NULLS LAST;