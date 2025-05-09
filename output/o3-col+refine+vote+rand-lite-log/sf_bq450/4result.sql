/* ---------------------------------------------------------------
   Comprehensive pre-2017 address report
   ---------------------------------------------------------------
   Everything is calculated for activity that happened strictly
   before 2017-01-01 00:00:00 UTC
   ( 1483228800 seconds  = 1483228800000000 micro-seconds )
-----------------------------------------------------------------*/

WITH
/* -------- 1) universal time constant ------------------------------------ */
const AS (
    SELECT 1483228800000000                AS "TS_CUTOFF_US",
           6.283185307179586              AS "TWO_PI"          -- 2*PI()
),

/* -------- 2) traces that qualify for balance / tx-level analysis -------- */
valid_traces AS (
    SELECT  "from_address",
            "to_address",
            CAST("value" AS FLOAT)               AS "value_wei",
            "gas_used",
            "trace_type",
            "call_type",
            "block_timestamp"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES t
           ,const
    WHERE   t."block_timestamp" < const."TS_CUTOFF_US"
      AND   (t."call_type" IS NULL OR t."call_type" NOT IN ('delegatecall',
                                                            'callcode',
                                                            'staticcall'))
),

/* -------- 3) basic incoming / outgoing ETH figures ---------------------- */
in_trace AS (
    SELECT  "to_address"                                       AS "address",
            COUNT(*)                                           AS "in_trace_count",
            COUNT(DISTINCT "from_address")                     AS "in_addr_count",
            COUNT_IF("value_wei" > 0)                          AS "in_transfer_count",
            AVG(IFF("value_wei" > 0, "value_wei", NULL))       AS "in_avg_amount_wei",
            SUM("value_wei")                                   AS "in_total_wei"
    FROM    valid_traces
    GROUP  BY 1
),
out_trace AS (
    SELECT  "from_address"                                     AS "address",
            COUNT(*)                                           AS "out_trace_count",
            COUNT(DISTINCT "to_address")                       AS "out_addr_count",
            COUNT_IF("value_wei" > 0)                          AS "out_transfer_count",
            AVG(IFF("value_wei" > 0, "value_wei", NULL))       AS "out_avg_amount_wei",
            SUM("value_wei")                                   AS "out_total_wei"
    FROM    valid_traces
    GROUP  BY 1
),

/* -------- 4) gas statistics for incoming call traces -------------------- */
gas_stats AS (
    SELECT  "to_address"                                       AS "address",
            AVG("gas_used")                                    AS "avg_gas_used",
            STDDEV_SAMP("gas_used")                            AS "std_gas_used"
    FROM    valid_traces
    WHERE   "trace_type" = 'call'
    GROUP  BY 1
),

/* -------- 5) transaction-fee debits (only sender pays fees) ------------- */
tx_fees AS (
    SELECT  "from_address"                                     AS "address",
            SUM("gas_price" * "receipt_gas_used")              AS "fee_wei"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t ,const
    WHERE   t."block_timestamp" < const."TS_CUTOFF_US"
    GROUP  BY 1
),

/* -------- 6) hourly activity vectors ------------------------------------ */
activity AS (
    SELECT  addr                                           AS "address",
            COUNT(*)                                       AS "n_events",
            COUNT(DISTINCT CAST(TO_TIMESTAMP(block_ts/1e6) AS DATE))  AS "active_days",
            SUM(COS(const."TWO_PI" * hr / 24))             AS "sum_cos",
            SUM(SIN(const."TWO_PI" * hr / 24))             AS "sum_sin"
    FROM   (
            /* union FROM + TO addresses so every interaction counts */
            SELECT "from_address" AS addr,
                   "block_timestamp" AS block_ts
            FROM   valid_traces
            UNION ALL
            SELECT "to_address"   AS addr,
                   "block_timestamp" AS block_ts
            FROM   valid_traces
           ) a ,const
    CROSS JOIN LATERAL (
        SELECT EXTRACT(HOUR FROM TO_TIMESTAMP(block_ts/1e6)) AS hr
    )
    GROUP BY addr
),
activity_metrics AS (
    SELECT  "address",
            "active_days",
            CASE
              WHEN "n_events" > 24 THEN
                   SQRT(POWER("sum_cos",2)+POWER("sum_sin",2)) / "n_events"
              ELSE NULL
            END                                              AS "R_active_hour"
    FROM    activity
),

/* -------- 7) ERC-20 / ERC-721 token movement statistics ----------------- */
token_xfer AS (
    SELECT * FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS ,const
    WHERE  "block_timestamp" < const."TS_CUTOFF_US"
),
token_in AS (
    SELECT  "to_address"                         AS "address",
            COUNT(*)                             AS "token_in_tnx",
            COUNT(DISTINCT "token_address")      AS "token_in_type",
            COUNT(DISTINCT "from_address")       AS "token_from_addr"
    FROM    token_xfer
    GROUP BY 1
),
token_out AS (
    SELECT  "from_address"                       AS "address",
            COUNT(*)                             AS "token_out_tnx",
            COUNT(DISTINCT "token_address")      AS "token_out_type",
            COUNT(DISTINCT "to_address")         AS "token_to_addr"
    FROM    token_xfer
    GROUP BY 1
),

/* -------- 8) mining rewards --------------------------------------------- */
rewards AS (
    SELECT  "to_address"                                     AS "address",
            SUM(CAST("value" AS FLOAT))                      AS "reward_wei"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES r ,const
    WHERE   r."block_timestamp" < const."TS_CUTOFF_US"
      AND   r."trace_type" = 'reward'
    GROUP  BY 1
),

/* -------- 9) contract creation counts (sent by address) ----------------- */
contract_creations AS (
    SELECT  "from_address"                                   AS "address",
            COUNT(*)                                         AS "contract_create_count"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t ,const
    WHERE   t."block_timestamp" < const."TS_CUTOFF_US"
      AND   t."receipt_contract_address" IS NOT NULL
    GROUP  BY 1
),

/* -------- 10) failed traces initiated by address ------------------------ */
failed_traces AS (
    SELECT  "from_address"                                   AS "address",
            COUNT(*)                                         AS "failure_count"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES f ,const
    WHERE   f."block_timestamp" < const."TS_CUTOFF_US"
      AND   f."status" = 0
    GROUP  BY 1
),

/* -------- 11) bytecode size for contract addresses themselves ----------- */
bytecode AS (
    SELECT  "address",
            LEN("bytecode")                                  AS "bytecode_size"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.CONTRACTS c ,const
    WHERE   c."block_timestamp" < const."TS_CUTOFF_US"
)

/* -------- 12) assemble master address list ------------------------------ */
,addresses AS (
    SELECT DISTINCT "address" FROM (
        SELECT "address" FROM in_trace
        UNION ALL SELECT "address" FROM out_trace
        UNION ALL SELECT "address" FROM token_in
        UNION ALL SELECT "address" FROM token_out
        UNION ALL SELECT "address" FROM rewards
        UNION ALL SELECT "address" FROM contract_creations
        UNION ALL SELECT "address" FROM failed_traces
        UNION ALL SELECT "address" FROM bytecode
    )
)

/* -------- 13) final select ---------------------------------------------- */
SELECT
        a."address",

        /* ---- Balance (ETH) ---- */
        (  COALESCE(it."in_total_wei",  0)
         - COALESCE(ot."out_total_wei",0)
         - COALESCE(f."fee_wei",       0) )      / 1e18          AS "balance",

        /* ---- Hourly activity consistency & days ---- */
        am."R_active_hour",
        am."active_days",

        /* ---- Incoming side metrics ---- */
        COALESCE(it."in_trace_count",0)          AS "in_trace_count",
        COALESCE(it."in_addr_count",0)           AS "in_addr_count",
        COALESCE(it."in_transfer_count",0)       AS "in_transfer_count",
        COALESCE(it."in_avg_amount_wei",0) /1e18 AS "in_avg_amount",
        COALESCE(gs."avg_gas_used",0)            AS "avg_gas_used",
        COALESCE(gs."std_gas_used",0)            AS "std_gas_used",

        /* ---- Outgoing side metrics ---- */
        COALESCE(ot."out_trace_count",0)         AS "out_trace_count",
        COALESCE(ot."out_addr_count",0)          AS "out_addr_count",
        COALESCE(ot."out_transfer_count",0)      AS "out_transfer_count",
        COALESCE(ot."out_avg_amount_wei",0)/1e18 AS "out_avg_amount",

        /* ---- Token interaction metrics ---- */
        COALESCE(ti."token_in_tnx",0)            AS "token_in_tnx",
        COALESCE(ti."token_in_type",0)           AS "token_in_type",
        COALESCE(ti."token_from_addr",0)         AS "token_from_addr",
        COALESCE(tox."token_out_tnx",0)          AS "token_out_tnx",
        COALESCE(tox."token_out_type",0)         AS "token_out_type",
        COALESCE(tox."token_to_addr",0)          AS "token_to_addr",

        /* ---- Mining reward & contracts ---- */
        COALESCE(rw."reward_wei",0)/1e18         AS "reward_amount",
        COALESCE(cc."contract_create_count",0)   AS "contract_create_count",

        /* ---- Failures & byte-code ---- */
        COALESCE(ft."failure_count",0)           AS "failure_count",
        bc."bytecode_size"

FROM    addresses                         a

        LEFT JOIN in_trace                it  ON it."address" = a."address"
        LEFT JOIN out_trace               ot  ON ot."address" = a."address"
        LEFT JOIN gas_stats               gs  ON gs."address" = a."address"
        LEFT JOIN tx_fees                 f   ON f ."address" = a."address"
        LEFT JOIN activity_metrics        am  ON am."address" = a."address"
        LEFT JOIN token_in                ti  ON ti."address" = a."address"
        LEFT JOIN token_out               tox ON tox."address" = a."address"
        LEFT JOIN rewards                 rw  ON rw."address" = a."address"
        LEFT JOIN contract_creations      cc  ON cc."address" = a."address"
        LEFT JOIN failed_traces           ft  ON ft."address" = a."address"
        LEFT JOIN bytecode                bc  ON bc."address" = a."address"

-- exclude completely inactive addresses (defensive – should not occur)
WHERE   COALESCE(it."in_trace_count",0)
       +COALESCE(ot."out_trace_count",0)
       +COALESCE(ti."token_in_tnx",0)
       +COALESCE(tox."token_out_tnx",0)
       +COALESCE(rw."reward_wei",0)
       +COALESCE(cc."contract_create_count",0)  > 0
;