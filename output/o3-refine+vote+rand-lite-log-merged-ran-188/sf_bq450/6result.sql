/* =========================================================================
   Comprehensive pre-2017 address report                                      
   -------------------------------------------------------------------------
   – Time-cut    : everything BEFORE 01-Jan-2017 00:00:00 UTC                 
   – Unit        : Wei ⇒ Ether by dividing by 1e18                           
   – Dialect     : Snowflake SQL                                             
   ========================================================================= */
WITH
/* -------------------------------------------------- */
cutoff AS (                    -- micro-seconds
    SELECT 1483228800000000 AS "ts"
),

/* ---------- successful ETH transactions (receipt OK or pre- Byzantium) --- */
tx_success AS (
    SELECT  *
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t , cutoff c
    WHERE   t."block_timestamp" < c."ts"
      AND  (t."receipt_status" = 1 OR t."receipt_status" IS NULL)
),

/* ---------- failed ETH transactions ------------------------------------- */
tx_failed AS (
    SELECT  *
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t , cutoff c
    WHERE   t."block_timestamp" < c."ts"
      AND   t."receipt_status" = 0
),

/* ---------- universe of addresses active before 2017 -------------------- */
addr_distinct AS (
    SELECT DISTINCT address
    FROM (
        SELECT "from_address" AS address FROM tx_success
        UNION
        SELECT "to_address"   AS address FROM tx_success
        UNION
        SELECT "from_address" FROM tx_failed
        UNION
        SELECT "from_address" FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES  tr , cutoff c
               WHERE tr."block_timestamp" < c."ts"
        UNION
        SELECT "to_address"   FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES  tr , cutoff c
               WHERE tr."block_timestamp" < c."ts"
        UNION
        SELECT "from_address" FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS tk , cutoff c
               WHERE tk."block_timestamp" < c."ts"
        UNION
        SELECT "to_address"   FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS tk , cutoff c
               WHERE tk."block_timestamp" < c."ts"
    )
    WHERE address IS NOT NULL
),

/* ---------- outgoing ETH flows  ----------------------------------------- */
out_tx AS (
    SELECT  "from_address"                                 AS address,
            COUNT(*)                                      AS out_trace_count,
            COUNT(DISTINCT COALESCE("to_address",'_'))    AS out_addr_count,
            SUM(CASE WHEN "value" <> 0 THEN 1 END)        AS out_transfer_count,
            AVG(CASE WHEN "value" <> 0 THEN "value"/1e18  END)  AS out_avg_amount,
            SUM("value")                                  AS out_value_sum,
            SUM("receipt_gas_used" * "gas_price")         AS fee_sum
    FROM    tx_success
    GROUP BY 1
),

/* ---------- incoming ETH flows ------------------------------------------ */
in_tx AS (
    SELECT  "to_address"                                   AS address,
            COUNT(*)                                      AS in_trace_count,
            COUNT(DISTINCT COALESCE("from_address",'_'))  AS in_addr_count,
            SUM(CASE WHEN "value" <> 0 THEN 1 END)        AS in_transfer_count,
            AVG(CASE WHEN "value" <> 0 THEN "value"/1e18  END) AS in_avg_amount,
            SUM("value")                                  AS in_value_sum
    FROM    tx_success
    GROUP BY 1
),

/* ---------- activity stats (days & hourly concentration) ---------------- */
activity AS (
    SELECT  a.address,
            COUNT(*)                                                        AS txn_cnt,
            COUNT(DISTINCT DATE_TRUNC('day', TO_TIMESTAMP_NTZ(t."block_timestamp"/1e6))) AS active_days,
            SUM(COS(2*PI()*EXTRACT(hour FROM TO_TIMESTAMP_NTZ(t."block_timestamp"/1e6))/24)) AS cos_sum,
            SUM(SIN(2*PI()*EXTRACT(hour FROM TO_TIMESTAMP_NTZ(t."block_timestamp"/1e6))/24)) AS sin_sum
    FROM    addr_distinct       a
    JOIN    tx_success          t
           ON t."from_address" = a.address OR t."to_address" = a.address
    GROUP BY a.address
),
activity_calc AS (
    SELECT  address,
            active_days,
            CASE WHEN txn_cnt > 24
                 THEN SQRT(cos_sum*cos_sum + sin_sum*sin_sum)/txn_cnt
            END AS R_active_hour
    FROM    activity
),

/* ---------- token statistics -------------------------------------------- */
token_in AS (
    SELECT  "to_address" AS address,
            COUNT(*)     AS token_in_tnx,
            COUNT(DISTINCT "token_address") AS token_in_type,
            COUNT(DISTINCT COALESCE("from_address",'_')) AS token_from_addr
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS tk , cutoff c
    WHERE   tk."block_timestamp" < c."ts"
    GROUP BY 1
),
token_out AS (
    SELECT  "from_address" AS address,
            COUNT(*)       AS token_out_tnx,
            COUNT(DISTINCT "token_address") AS token_out_type,
            COUNT(DISTINCT COALESCE("to_address",'_'))   AS token_to_addr
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS tk , cutoff c
    WHERE   tk."block_timestamp" < c."ts"
    GROUP BY 1
),

/* ---------- mining rewards ---------------------------------------------- */
reward AS (
    SELECT  "to_address" AS address,
            SUM("value")/1e18 AS reward_amount
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES tr , cutoff c
    WHERE   tr."block_timestamp" < c."ts"
      AND   tr."trace_type" = 'reward'
    GROUP BY 1
),

/* ---------- contract creations ------------------------------------------ */
contract_create AS (
    SELECT  "from_address" AS address,
            COUNT(*)       AS contract_create_count
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES tr , cutoff c
    WHERE   tr."block_timestamp" < c."ts"
      AND   tr."trace_type" = 'create'
    GROUP BY 1
),

/* ---------- gas statistics for incoming CALL traces --------------------- */
gas_stats AS (
    SELECT  "to_address" AS address,
            AVG("gas_used")                AS avg_gas_used,
            STDDEV_SAMP("gas_used")        AS std_gas_used
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES tr , cutoff c
    WHERE   tr."block_timestamp" < c."ts"
      AND   tr."trace_type" = 'call'
      AND  (tr."call_type" IS NULL OR tr."call_type" NOT IN ('delegatecall','callcode','staticcall'))
      AND   tr."status" = 1
      AND   tr."gas_used" IS NOT NULL
    GROUP BY 1
),

/* ---------- failures ---------------------------------------------------- */
failures AS (
    SELECT  "from_address" AS address,
            COUNT(*)       AS failure_count
    FROM    tx_failed
    GROUP BY 1
),

/* ---------- byte-code size (avg) of contracts created ------------------- */
bytecode AS (
    SELECT  cr."from_address"                           AS address,
            AVG(LENGTH(co."bytecode"))                  AS bytecode_size
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES    cr
    JOIN    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.CONTRACTS co
           ON cr."to_address" = co."address"
    JOIN    cutoff c
           ON cr."block_timestamp" < c."ts"
    WHERE   cr."trace_type" = 'create'
    GROUP BY 1
),

/* ---------- balance computation ----------------------------------------- */
balance_calc AS (
    SELECT  a.address,
            ( COALESCE(inn.in_value_sum ,0)
            - COALESCE(outt.out_value_sum,0)
            - COALESCE(outt.fee_sum      ,0) ) / 1e18  AS balance
    FROM    addr_distinct a
    LEFT JOIN in_tx  inn  ON a.address = inn.address
    LEFT JOIN out_tx outt ON a.address = outt.address
)

/* ======================= FINAL SELECT =================================== */
SELECT
    a.address,

    /* ---- balance & activity ------------------------------------------- */
    bal.balance,
    act.R_active_hour,
    act.active_days,

    /* ---- incoming metrics --------------------------------------------- */
    COALESCE(inn.in_trace_count ,0)  AS in_trace_count,
    COALESCE(inn.in_addr_count  ,0)  AS in_addr_count,
    COALESCE(inn.in_transfer_count,0)AS in_transfer_count,
    COALESCE(inn.in_avg_amount  ,0)  AS in_avg_amount,
    COALESCE(gs.avg_gas_used    ,0)  AS avg_gas_used,
    COALESCE(gs.std_gas_used    ,0)  AS std_gas_used,

    /* ---- outgoing metrics --------------------------------------------- */
    COALESCE(outt.out_trace_count ,0)   AS out_trace_count,
    COALESCE(outt.out_addr_count  ,0)   AS out_addr_count,
    COALESCE(outt.out_transfer_count,0) AS out_transfer_count,
    COALESCE(outt.out_avg_amount  ,0)   AS out_avg_amount,

    /* ---- token metrics ------------------------------------------------- */
    COALESCE(ti.token_in_tnx   ,0)   AS token_in_tnx,
    COALESCE(ti.token_in_type  ,0)   AS token_in_type,
    COALESCE(ti.token_from_addr,0)   AS token_from_addr,
    COALESCE(tox.token_out_tnx ,0)   AS token_out_tnx,
    COALESCE(tox.token_out_type,0)   AS token_out_type,
    COALESCE(tox.token_to_addr ,0)   AS token_to_addr,

    /* ---- mining / contracts / failures -------------------------------- */
    COALESCE(rw.reward_amount         ,0) AS reward_amount,
    COALESCE(cc.contract_create_count ,0) AS contract_create_count,
    COALESCE(fl.failure_count         ,0) AS failure_count,
    COALESCE(bc.bytecode_size         ,0) AS bytecode_size

FROM    addr_distinct a
LEFT JOIN balance_calc    bal ON bal.address = a.address
LEFT JOIN activity_calc   act ON act.address = a.address
LEFT JOIN in_tx           inn ON inn.address = a.address
LEFT JOIN out_tx          outt ON outt.address = a.address
LEFT JOIN gas_stats       gs  ON gs.address  = a.address
LEFT JOIN token_in        ti  ON ti.address  = a.address
LEFT JOIN token_out       tox ON tox.address = a.address
LEFT JOIN reward          rw  ON rw.address  = a.address
LEFT JOIN contract_create cc  ON cc.address  = a.address
LEFT JOIN failures        fl  ON fl.address  = a.address
LEFT JOIN bytecode        bc  ON bc.address  = a.address

ORDER BY bal.balance DESC NULLS LAST;