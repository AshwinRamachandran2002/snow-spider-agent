/* =============================================================
   Comprehensive Ethereum‑address report (‑∞ … 2017‑01‑01 UTC)
   Time stored : micro‑seconds since Unix epoch
   ETH units   : Wei ÷ 1e18
   =============================================================*/
WITH
/* ---------- constants ----------------------------------------------------- */
limits AS (
    SELECT
        1483228800000000  AS cutoff_ts ,   /* 2017‑01‑01 00:00:00 UTC (µs) */
        1000000           AS us2s     ,
        1e18              AS wei2eth
),

/* ---------- traces before 2017  (exclude delegate / callcode / static) ---- */
traces_pre17 AS (
    SELECT
        t."block_timestamp",
        t."block_number",
        t."transaction_hash",
        t."value",
        t."gas_used",
        t."from_address",
        t."to_address",
        t."trace_type",
        t."call_type",
        t."status"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES t , limits l
    WHERE t."block_timestamp" < l.cutoff_ts
      AND ( t."call_type" IS NULL
            OR UPPER(t."call_type") NOT IN ('DELEGATECALL','CALLCODE','STATICCALL') )
),

/* ---------- successful plain calls --------------------------------------- */
traces_ok AS (
    SELECT *
    FROM   traces_pre17
    WHERE  "trace_type" = 'call'
      AND  "status"     = 1
),

/* ---------- reward traces ------------------------------------------------- */
reward_traces AS (
    SELECT  "to_address"                       AS ADDRESS ,
            SUM("value")                       AS reward_wei
    FROM    traces_pre17
    WHERE   "trace_type" = 'reward'
    GROUP BY "to_address"
),

/* ---------- contract creation counts ------------------------------------- */
contract_creations AS (
    SELECT  "from_address"                     AS ADDRESS ,
            COUNT(*)                           AS contract_create_count
    FROM    traces_pre17
    WHERE   "trace_type" = 'create'
    GROUP BY "from_address"
),

/* ---------- failed traces count ------------------------------------------ */
failure_counts AS (
    SELECT  "from_address"                     AS ADDRESS ,
            COUNT(*)                           AS failure_count
    FROM    traces_pre17
    WHERE   "status" = 0
    GROUP BY "from_address"
),

/* ---------- ETH inbound -------------------------------------------------- */
eth_in AS (
    SELECT
        "to_address"                           AS ADDRESS,
        SUM("value")                           AS in_wei,
        COUNT(*)                               AS in_trace_count,
        COUNT_IF("value" <> 0)                 AS in_transfer_count,
        COUNT(DISTINCT "from_address")         AS in_addr_count,
        AVG("value")                           AS in_avg_amount_wei,
        AVG("gas_used")                        AS in_avg_gas_used,
        STDDEV_POP("gas_used")                 AS in_std_gas_used
    FROM traces_ok
    GROUP BY "to_address"
),

/* ---------- ETH outbound ------------------------------------------------- */
eth_out AS (
    SELECT
        "from_address"                         AS ADDRESS,
        SUM("value")                           AS out_wei,
        COUNT(*)                               AS out_trace_count,
        COUNT_IF("value" <> 0)                 AS out_transfer_count,
        COUNT(DISTINCT "to_address")           AS out_addr_count,
        AVG("value")                           AS out_avg_amount_wei
    FROM traces_ok
    GROUP BY "from_address"
),

/* ---------- combine ETH in & out ----------------------------------------- */
eth_flow AS (
    SELECT
        COALESCE(i.ADDRESS , o.ADDRESS)            AS ADDRESS,
        COALESCE(i.in_wei             , 0)         AS in_wei,
        COALESCE(o.out_wei            , 0)         AS out_wei,
        COALESCE(i.in_trace_count     , 0)         AS in_trace_count,
        COALESCE(o.out_trace_count    , 0)         AS out_trace_count,
        COALESCE(i.in_addr_count      , 0)         AS in_addr_count,
        COALESCE(o.out_addr_count     , 0)         AS out_addr_count,
        COALESCE(i.in_transfer_count  , 0)         AS in_transfer_count,
        COALESCE(o.out_transfer_count , 0)         AS out_transfer_count,
        i.in_avg_amount_wei,
        o.out_avg_amount_wei,
        i.in_avg_gas_used                             AS avg_gas_used,
        i.in_std_gas_used                             AS std_gas_used
    FROM eth_in i
    FULL OUTER JOIN eth_out o
         ON i.ADDRESS = o.ADDRESS
),

/* ---------- transaction fees (successful tx) ----------------------------- */
tx_fees AS (
    SELECT  tr."from_address"                    AS ADDRESS,
            SUM(tr."receipt_gas_used" * tr."gas_price") AS fee_wei
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS tr , limits l
    WHERE   tr."block_timestamp" < l.cutoff_ts
      AND   tr."receipt_status"  = 1
    GROUP BY tr."from_address"
),

/* ---------- activity stats ----------------------------------------------- */
activity AS (
    SELECT
        addr                                      AS ADDRESS,
        COUNT(*)                                  AS activity_total,
        COUNT(DISTINCT DATE_TRUNC('day',
                   TO_TIMESTAMP(tstmp / 1000000))) AS active_days,
        /* hour‑of‑day concentration */
        SQRT(
             POWER(SUM(COS(2*PI()*DATE_PART('hour',
                       TO_TIMESTAMP(tstmp / 1000000))/24)),2)
           + POWER(SUM(SIN(2*PI()*DATE_PART('hour',
                       TO_TIMESTAMP(tstmp / 1000000))/24)),2)
        ) / COUNT(*)                              AS R_active_hour
    FROM (
        SELECT "from_address" AS addr, "block_timestamp" AS tstmp FROM traces_ok
        UNION ALL
        SELECT "to_address"   AS addr, "block_timestamp" AS tstmp FROM traces_ok
    )
    GROUP BY addr
    HAVING COUNT(*) > 24
),

/* ---------- token transfers – incoming ----------------------------------- */
token_in AS (
    SELECT  tt."to_address"                      AS ADDRESS,
            COUNT(*)                             AS token_in_tnx,
            COUNT(DISTINCT tt."token_address")   AS token_in_type,
            COUNT(DISTINCT tt."from_address")    AS token_from_addr
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS tt , limits l
    WHERE   tt."block_timestamp" < l.cutoff_ts
    GROUP BY tt."to_address"
),

/* ---------- token transfers – outgoing ----------------------------------- */
token_out AS (
    SELECT  tt."from_address"                    AS ADDRESS,
            COUNT(*)                             AS token_out_tnx,
            COUNT(DISTINCT tt."token_address")   AS token_out_type,
            COUNT(DISTINCT tt."to_address")      AS token_to_addr
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS tt , limits l
    WHERE   tt."block_timestamp" < l.cutoff_ts
    GROUP BY tt."from_address"
),

/* ---------- merge token statistics --------------------------------------- */
token_stats AS (
    SELECT
        COALESCE(i.ADDRESS , o.ADDRESS)               AS ADDRESS,
        COALESCE(i.token_in_tnx ,  0)                 AS token_in_tnx,
        COALESCE(i.token_in_type, 0)                  AS token_in_type,
        COALESCE(i.token_from_addr,0)                 AS token_from_addr,
        COALESCE(o.token_out_tnx, 0)                  AS token_out_tnx,
        COALESCE(o.token_out_type,0)                  AS token_out_type,
        COALESCE(o.token_to_addr , 0)                 AS token_to_addr
    FROM token_in i
    FULL OUTER JOIN token_out o
         ON i.ADDRESS = o.ADDRESS
),

/* ---------- contract byte‑code sizes ------------------------------------- */
bytecodes AS (
    SELECT
        c."address"                                  AS ADDRESS,
        (LENGTH(c."bytecode") - 2) / 2               AS bytecode_size  /* remove 0x & count */
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.CONTRACTS c , limits l
    WHERE c."block_timestamp" < l.cutoff_ts
),

/* ---------- comprehensive address list ----------------------------------- */
all_addresses AS (
        SELECT DISTINCT ADDRESS FROM eth_flow
 UNION SELECT DISTINCT ADDRESS FROM activity
 UNION SELECT DISTINCT ADDRESS FROM reward_traces
 UNION SELECT DISTINCT ADDRESS FROM contract_creations
 UNION SELECT DISTINCT ADDRESS FROM failure_counts
 UNION SELECT DISTINCT ADDRESS FROM token_stats
 UNION SELECT DISTINCT ADDRESS FROM bytecodes
),

/* ---------- final assembly ----------------------------------------------- */
final AS (
    SELECT
        a.ADDRESS,

        /* balance --------------------------------------------------------- */
        (  COALESCE(ef.in_wei ,0)
         + COALESCE(rt.reward_wei ,0)
         - COALESCE(ef.out_wei,0)
         - COALESCE(tf.fee_wei ,0) ) / l.wei2eth              AS BALANCE,

        /* activity -------------------------------------------------------- */
        ac.R_active_hour,
        ac.active_days,

        /* inbound metrics ------------------------------------------------- */
        ef.in_trace_count,
        ef.in_addr_count,
        ef.in_transfer_count,
        COALESCE(ef.in_avg_amount_wei ,0)  / l.wei2eth        AS in_avg_amount,
        ef.avg_gas_used,
        ef.std_gas_used,

        /* outbound metrics ------------------------------------------------ */
        ef.out_trace_count,
        ef.out_addr_count,
        ef.out_transfer_count,
        COALESCE(ef.out_avg_amount_wei,0) / l.wei2eth         AS out_avg_amount,

        /* token stats ----------------------------------------------------- */
        ts.token_in_tnx,
        ts.token_in_type,
        ts.token_from_addr,
        ts.token_out_tnx,
        ts.token_out_type,
        ts.token_to_addr,

        /* rewards / contracts / misc ------------------------------------- */
        COALESCE(rt.reward_wei ,0) / l.wei2eth               AS reward_amount,
        cc.contract_create_count,
        fc.failure_count,
        bc.bytecode_size
    FROM all_addresses        a
    LEFT JOIN eth_flow        ef ON a.ADDRESS = ef.ADDRESS
    LEFT JOIN reward_traces   rt ON a.ADDRESS = rt.ADDRESS
    LEFT JOIN tx_fees         tf ON a.ADDRESS = tf.ADDRESS
    LEFT JOIN activity        ac ON a.ADDRESS = ac.ADDRESS
    LEFT JOIN token_stats     ts ON a.ADDRESS = ts.ADDRESS
    LEFT JOIN contract_creations cc ON a.ADDRESS = cc.ADDRESS
    LEFT JOIN failure_counts  fc ON a.ADDRESS = fc.ADDRESS
    LEFT JOIN bytecodes       bc ON a.ADDRESS = bc.ADDRESS
    CROSS JOIN limits         l
)

/* ---------- result ------------------------------------------------------- */
SELECT *
FROM   final
ORDER  BY BALANCE DESC NULLS LAST, ADDRESS;