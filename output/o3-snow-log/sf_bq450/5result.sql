/* =======================================================================
   Comprehensive report for ALL Ethereum addresses that were active
   BEFORE 1-Jan-2017 (1483228800000000 µs).  
   All ETH-denominated values are finally converted to Ether ( ÷ 1e18 ).
   -----------------------------------------------------------------------
   NOTE: the query is written for Snowflake SQL. It relies only on the
         six tables that exist in catalog
         ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.*
   =======================================================================*/

WITH
/* ----------------------------------------------------------
   Cut-off filtered source tables (to make predicates shorter)
   ----------------------------------------------------------*/
"TX"  AS (
    SELECT *
    FROM   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRANSACTIONS"
    WHERE  "block_timestamp" < 1483228800000000                       -- < 1-Jan-2017
),
"TR"  AS (
    SELECT *
    FROM   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
    WHERE  "block_timestamp" < 1483228800000000
),
"TT"  AS (
    SELECT *
    FROM   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS"
    WHERE  "block_timestamp" < 1483228800000000
),
"CT"  AS (
    SELECT *
    FROM   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."CONTRACTS"
    WHERE  "block_timestamp" < 1483228800000000
),

/* ----------------------------------------------------------
   Universe of addresses that had ANY activity before 2017
   ----------------------------------------------------------*/
"ADDRS" AS (
    SELECT DISTINCT "address"
    FROM (
        SELECT "from_address"  AS "address" FROM "TX"
        UNION
        SELECT "to_address"    AS "address" FROM "TX"
        UNION
        SELECT "from_address"  AS "address" FROM "TR"
        UNION
        SELECT "to_address"    AS "address" FROM "TR"
        UNION
        SELECT "from_address"  AS "address" FROM "TT"
        UNION
        SELECT "to_address"    AS "address" FROM "TT"
        UNION
        SELECT "address"       AS "address" FROM "CT"
    )
    WHERE  "address" IS NOT NULL
),

/* ----------------------------------------------------------
   ETH traces  (exclude delegatecall / callcode / staticcall)
   ----------------------------------------------------------*/
"IN_TRACES" AS (
    SELECT
        "to_address"                         AS "address",
        SUM("value")                         AS "eth_in",
        COUNT(*)                             AS "in_trace_count",
        COUNT_IF("value" > 0)               AS "in_transfer_count",
        COUNT(DISTINCT "from_address")       AS "in_addr_count",
        AVG("value")                         AS "in_avg_amount",
        AVG("gas_used")                      AS "avg_gas_used",
        STDDEV("gas_used")                   AS "std_gas_used"
    FROM "TR"
    WHERE "trace_type" = 'call'
      AND ("call_type" IS NULL OR "call_type" = 'call')
      AND "status" = 1
    GROUP BY "to_address"
),
"OUT_TRACES" AS (
    SELECT
        "from_address"                       AS "address",
        SUM("value")                         AS "eth_out",
        COUNT(*)                             AS "out_trace_count",
        COUNT_IF("value" > 0)               AS "out_transfer_count",
        COUNT(DISTINCT "to_address")         AS "out_addr_count",
        AVG("value")                         AS "out_avg_amount"
    FROM "TR"
    WHERE "trace_type" = 'call'
      AND ("call_type" IS NULL OR "call_type" = 'call')
      AND "status" = 1
    GROUP BY "from_address"
),

/* ----------------------------------------------------------
   Transaction fees (successful on-chain TXs)
   ----------------------------------------------------------*/
"FEES" AS (
    SELECT
        "from_address"                       AS "address",
        SUM("gas_price" * "receipt_gas_used") AS "fee_wei"
    FROM "TX"
    WHERE "receipt_status" = 1
    GROUP BY "from_address"
),

/* ----------------------------------------------------------
   Token transfer metrics
   ----------------------------------------------------------*/
"TOK_IN" AS (
    SELECT
        "to_address"                         AS "address",
        COUNT(*)                             AS "token_in_tnx",
        COUNT(DISTINCT "token_address")      AS "token_in_type",
        COUNT(DISTINCT "from_address")       AS "token_from_addr"
    FROM "TT"
    GROUP BY "to_address"
),
"TOK_OUT" AS (
    SELECT
        "from_address"                       AS "address",
        COUNT(*)                             AS "token_out_tnx",
        COUNT(DISTINCT "token_address")      AS "token_out_type",
        COUNT(DISTINCT "to_address")         AS "token_to_addr"
    FROM "TT"
    GROUP BY "from_address"
),

/* ----------------------------------------------------------
   Mining rewards   (ETH, exclude uncle vs block distinction)
   ----------------------------------------------------------*/
"REWARD" AS (
    SELECT
        "to_address"                         AS "address",
        SUM("value")                         AS "reward_wei"
    FROM "TR"
    WHERE "trace_type" = 'reward'
    GROUP BY "to_address"
),

/* ----------------------------------------------------------
   Contract creations initiated by the address
   ----------------------------------------------------------*/
"CONTRACT_CREATE" AS (
    SELECT
        "from_address"                       AS "address",
        COUNT(*)                             AS "contract_create_count"
    FROM "TR"
    WHERE "trace_type" = 'create'
    GROUP BY "from_address"
),

/* ----------------------------------------------------------
   Failed user-transactions
   ----------------------------------------------------------*/
"FAIL" AS (
    SELECT
        "from_address"                       AS "address",
        COUNT(*)                             AS "failure_count"
    FROM "TX"
    WHERE "receipt_status" = 0
    GROUP BY "from_address"
),

/* ----------------------------------------------------------
   Byte-code length for contracts whose OWN address appears
   ----------------------------------------------------------*/
"BYTECODE" AS (
    SELECT
        "address"                            AS "address",
        LENGTH("bytecode")                   AS "bytecode_size"
    FROM "CT"
),

/* ----------------------------------------------------------
   Hourly activity consistency (address must have >24 events)
   R = sqrt( (Σcosθ)² + (Σsinθ)² ) / n
   θ = 2π * hour / 24
   ----------------------------------------------------------*/
"ACTIVITY" AS (
    SELECT
        "addr"                               AS "address",
        COUNT(*)                             AS "total_events",
        COUNT(DISTINCT DATE_TRUNC('day',
               TO_TIMESTAMP_NTZ("block_ts" / 1000000)))          AS "active_days",
        SQRT(  POWER(SUM(COS(2 * PI() * "hour_of_day" / 24)),2)
             + POWER(SUM(SIN(2 * PI() * "hour_of_day" / 24)),2)
            ) / COUNT(*)                    AS "R_active_hour"
    FROM (
        /* sender side */
        SELECT
            "from_address"  AS "addr",
            MOD(FLOOR(("block_timestamp" / 1000000) / 3600),24) AS "hour_of_day",
            "block_timestamp" AS "block_ts"
        FROM "TX"
        UNION ALL
        /* receiver side */
        SELECT
            "to_address"    AS "addr",
            MOD(FLOOR(("block_timestamp" / 1000000) / 3600),24) AS "hour_of_day",
            "block_timestamp" AS "block_ts"
        FROM "TX"
    )
    WHERE "addr" IS NOT NULL
    GROUP BY "addr"
    HAVING COUNT(*) > 24      -- “significant activity”
)

/* ======================================================================
   FINAL REPORT
   ======================================================================*/
SELECT
    A."address",

    /* --------------  Net balance (ETH) --------------*/
    ROUND( ( COALESCE(IN_TR."eth_in",   0)
            -COALESCE(OUT_TR."eth_out", 0)
            -COALESCE(FEES."fee_wei",   0) ) / 1e18 , 4)       AS "balance",

    /* --------------  Activity metrics ---------------*/
    ACT."R_active_hour",
    ACT."active_days",

    /* Incoming traces */
    COALESCE(IN_TR."in_trace_count",      0)  AS "in_trace_count",
    COALESCE(IN_TR."in_addr_count",       0)  AS "in_addr_count",
    COALESCE(IN_TR."in_transfer_count",   0)  AS "in_transfer_count",
    ROUND( COALESCE(IN_TR."in_avg_amount",0) / 1e18 , 4)       AS "in_avg_amount",
    COALESCE(IN_TR."avg_gas_used",        0)  AS "avg_gas_used",
    COALESCE(IN_TR."std_gas_used",        0)  AS "std_gas_used",

    /* Outgoing traces */
    COALESCE(OUT_TR."out_trace_count",     0) AS "out_trace_count",
    COALESCE(OUT_TR."out_addr_count",      0) AS "out_addr_count",
    COALESCE(OUT_TR."out_transfer_count",  0) AS "out_transfer_count",
    ROUND( COALESCE(OUT_TR."out_avg_amount",0)/1e18 , 4)      AS "out_avg_amount",

    /* Token transfer metrics */
    COALESCE(TI."token_in_tnx",   0)  AS "token_in_tnx",
    COALESCE(TI."token_in_type",  0)  AS "token_in_type",
    COALESCE(TI."token_from_addr",0)  AS "token_from_addr",
    COALESCE(TOU."token_out_tnx",  0) AS "token_out_tnx",
    COALESCE(TOU."token_out_type", 0) AS "token_out_type",
    COALESCE(TOU."token_to_addr",  0) AS "token_to_addr",

    /* Mining rewards & contracts */
    ROUND( COALESCE(RWD."reward_wei",0) / 1e18 , 4)            AS "reward_amount",
    COALESCE(CC."contract_create_count",0) AS "contract_create_count",

    /* Failures & byte-code */
    COALESCE(FL."failure_count",0)          AS "failure_count",
    COALESCE(BC."bytecode_size",0)          AS "bytecode_size"

FROM        "ADDRS"                                  A
LEFT JOIN   "IN_TRACES"          IN_TR   ON A."address" = IN_TR."address"
LEFT JOIN   "OUT_TRACES"         OUT_TR  ON A."address" = OUT_TR."address"
LEFT JOIN   "FEES"               FEES    ON A."address" = FEES."address"
LEFT JOIN   "ACTIVITY"           ACT     ON A."address" = ACT."address"
LEFT JOIN   "TOK_IN"             TI      ON A."address" = TI."address"
LEFT JOIN   "TOK_OUT"            TOU     ON A."address" = TOU."address"
LEFT JOIN   "REWARD"             RWD     ON A."address" = RWD."address"
LEFT JOIN   "CONTRACT_CREATE"    CC      ON A."address" = CC."address"
LEFT JOIN   "FAIL"               FL      ON A."address" = FL."address"
LEFT JOIN   "BYTECODE"           BC      ON A."address" = BC."address"

/* Exclude any addresses that, for some reason, ended up with no
   pre-2017 on-chain interaction at all (safety filter)               */
WHERE
      COALESCE(IN_TR."in_trace_count", 0)
    + COALESCE(OUT_TR."out_trace_count",0)
    + COALESCE(TI."token_in_tnx",0)
    + COALESCE(TOU."token_out_tnx",0) > 0

ORDER BY "balance" DESC NULLS LAST;