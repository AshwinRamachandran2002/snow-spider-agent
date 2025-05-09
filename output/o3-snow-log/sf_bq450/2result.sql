/* ------------------------------------------------------------
   Comprehensive   pre-2017   Ethereum-address   activity report
   ------------------------------------------------------------
   NOTE: all timestamps are stored in µ-seconds; the cut-off
         2017-01-01 00:00:00 UTC = 1483228800 × 1 000 000
---------------------------------------------------------------- */
WITH
/* 1) ------------------------------------------------------------ */
cutoff AS (
    SELECT 1483228800000000::NUMBER AS ts_cutoff
),

/* 2) -------- successful, non-delegate/static/callcode traces ---- */
traces_ok AS (
    SELECT
        "from_address",
        "to_address",
        "value"::NUMBER                      AS val_wei,
        COALESCE("gas_used",0)::NUMBER       AS gas_used,
        COALESCE("gas",0)::NUMBER            AS gas_limit,
        "status",
        "trace_type",
        "call_type",
        "block_timestamp"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES , cutoff
    WHERE "block_timestamp" < ts_cutoff
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
),

/* 3) ---------------- incoming / outgoing aggregates ------------- */
in_traces AS (
    SELECT
        "to_address"                       AS address,
        COUNT(*)                           AS in_trace_count,
        COUNT(DISTINCT "from_address")     AS in_addr_count,
        COUNT_IF(val_wei <> 0)             AS in_transfer_count,
        AVG(val_wei)/1e18                  AS in_avg_amount,
        AVG(CASE WHEN "call_type" = 'call' THEN gas_used END)         AS avg_gas_used,
        STDDEV_SAMP(CASE WHEN "call_type" = 'call' THEN gas_used END) AS std_gas_used,
        SUM(val_wei)                       AS in_value_sum
    FROM traces_ok
    WHERE "status" = 1
    GROUP BY "to_address"
),
out_traces AS (
    SELECT
        "from_address"                    AS address,
        COUNT(*)                          AS out_trace_count,
        COUNT(DISTINCT "to_address")      AS out_addr_count,
        COUNT_IF(val_wei <> 0)            AS out_transfer_count,
        AVG(val_wei)/1e18                 AS out_avg_amount,
        SUM(val_wei)                      AS out_value_sum
    FROM traces_ok
    WHERE "status" = 1
    GROUP BY "from_address"
),

/* 4) ---------------- transaction fees (successful tx) ----------- */
tx_fees AS (
    SELECT
        "from_address" AS address,
        SUM( COALESCE("gas_price",0)::NUMBER
            * COALESCE("receipt_gas_used",0)::NUMBER ) AS fee_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS , cutoff
    WHERE "block_timestamp" < ts_cutoff
      AND COALESCE("receipt_status",1) = 1
    GROUP BY "from_address"
),

/* 5) ------------- hourly activity uniformity & active days ------ */
activity AS (
    SELECT
        addr                             AS address,
        cnt                              AS total_events,
        SQRT( POWER(cs,2) + POWER(ss,2) ) / cnt   AS R_active_hour,
        days_active
    FROM (
        SELECT
            addr,
            COUNT(*)                                       AS cnt,
            COUNT(DISTINCT DATE(ts))                       AS days_active,
            SUM( COS( 2 * PI() * hr / 24 ) )               AS cs,
            SUM( SIN( 2 * PI() * hr / 24 ) )               AS ss
        FROM (
            SELECT
                CASE WHEN role = 'from'
                     THEN "from_address"
                     ELSE "to_address"
                END                                         AS addr,
                TO_TIMESTAMP("block_timestamp"/1e6)         AS ts,
                DATE_PART('hour', TO_TIMESTAMP("block_timestamp"/1e6)) AS hr
            FROM traces_ok,
                 LATERAL ( SELECT 'from' AS role UNION ALL SELECT 'to' ) r
            WHERE (r.role = 'from' AND "from_address" IS NOT NULL)
               OR (r.role = 'to'   AND "to_address"   IS NOT NULL)
        )
        GROUP BY addr
        HAVING COUNT(*) > 24
    )
),

/* 6) -------------------------- mining rewards ------------------- */
rewards AS (
    SELECT
        "to_address"                    AS address,
        SUM("value"::NUMBER)/1e18       AS reward_amount
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES , cutoff
    WHERE "block_timestamp" < ts_cutoff
      AND "trace_type" = 'reward'
    GROUP BY "to_address"
),

/* 7) ------------- contract creation count & byte-code size ------ */
contract_creations AS (
    SELECT
        "from_address"               AS address,
        COUNT(*)                     AS contract_create_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES , cutoff
    WHERE "block_timestamp" < ts_cutoff
      AND "trace_type" = 'create'
    GROUP BY "from_address"
),
bytecode AS (
    SELECT
        t."from_address"  AS address,
        AVG( LENGTH(c."bytecode") ) AS bytecode_size
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES    t
    JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.CONTRACTS c
          ON t."to_address" = c."address"
    JOIN cutoff
          ON t."block_timestamp" < ts_cutoff
    WHERE t."trace_type" = 'create'
    GROUP BY t."from_address"
),

/* 8) ----------------------- failed traces ----------------------- */
failures AS (
    SELECT
        "from_address" AS address,
        COUNT(*)       AS failure_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES , cutoff
    WHERE "block_timestamp" < ts_cutoff
      AND "status" = 0
    GROUP BY "from_address"
),

/* 9) ---------------------- token transfers ---------------------- */
tok_in AS (
    SELECT
        "to_address"                    AS address,
        COUNT(*)                        AS token_in_tnx,
        COUNT(DISTINCT "token_address") AS token_in_type,
        COUNT(DISTINCT "from_address")  AS token_from_addr
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS , cutoff
    WHERE "block_timestamp" < ts_cutoff
    GROUP BY "to_address"
),
tok_out AS (
    SELECT
        "from_address"                  AS address,
        COUNT(*)                        AS token_out_tnx,
        COUNT(DISTINCT "token_address") AS token_out_type,
        COUNT(DISTINCT "to_address")    AS token_to_addr
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS , cutoff
    WHERE "block_timestamp" < ts_cutoff
    GROUP BY "from_address"
),

/* 10) --------------- compute net balance (ETH) ------------------ */
money AS (
    SELECT
        COALESCE(i.address, o.address) AS address,
        COALESCE(i.in_value_sum ,0)    AS in_sum_wei,
        COALESCE(o.out_value_sum,0)    AS out_sum_wei
    FROM in_traces i
    FULL OUTER JOIN out_traces o
      ON i.address = o.address
),
balance AS (
    SELECT
        m.address,
        ( m.in_sum_wei - m.out_sum_wei - COALESCE(f.fee_wei,0) ) / 1e18 AS balance
    FROM money m
    LEFT JOIN tx_fees f
      ON m.address = f.address
)

/* =========================== FINAL SELECT ====================== */
SELECT
       addr.address                                  AS address
     , bal.balance                                   AS balance
     , act.R_active_hour                             AS R_active_hour
     , act.days_active                               AS active_days      -- fixed alias

     /* incoming */
     , it.in_trace_count
     , it.in_addr_count
     , it.in_transfer_count
     , it.in_avg_amount
     , it.avg_gas_used
     , it.std_gas_used

     /* outgoing */
     , ot.out_trace_count
     , ot.out_addr_count
     , ot.out_transfer_count
     , ot.out_avg_amount

     /* token metrics */
     , ti.token_in_tnx
     , ti.token_in_type
     , ti.token_from_addr
     , tokt.token_out_tnx
     , tokt.token_out_type
     , tokt.token_to_addr

     /* rewards & contracts & failures */
     , rw.reward_amount
     , cc.contract_create_count
     , fl.failure_count
     , bc.bytecode_size

FROM (
        /* distinct addresses active before 2017-01-01 */
        SELECT DISTINCT address FROM (
              SELECT "from_address" AS address FROM traces_ok
              UNION
              SELECT "to_address"   AS address FROM traces_ok
              UNION
              SELECT "from_address" AS address
              FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS , cutoff
              WHERE "block_timestamp" < ts_cutoff
              UNION
              SELECT "to_address"   AS address
              FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS , cutoff
              WHERE "block_timestamp" < ts_cutoff
              UNION
              SELECT "from_address" AS address
              FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES , cutoff
              WHERE "block_timestamp" < ts_cutoff
                AND "trace_type" = 'reward'
        )
     ) addr

LEFT JOIN balance            bal  ON addr.address = bal.address
LEFT JOIN activity           act  ON addr.address = act.address
LEFT JOIN in_traces          it   ON addr.address = it.address
LEFT JOIN out_traces         ot   ON addr.address = ot.address
LEFT JOIN tok_in             ti   ON addr.address = ti.address
LEFT JOIN tok_out            tokt ON addr.address = tokt.address
LEFT JOIN rewards            rw   ON addr.address = rw.address
LEFT JOIN contract_creations cc   ON addr.address = cc.address
LEFT JOIN failures           fl   ON addr.address = fl.address
LEFT JOIN bytecode           bc   ON addr.address = bc.address

/* drop rows with absolutely no metrics */
WHERE COALESCE(
        bal.balance,
        it.in_trace_count,  ot.out_trace_count,
        ti.token_in_tnx,    tokt.token_out_tnx,
        rw.reward_amount,   cc.contract_create_count,
        fl.failure_count,   bc.bytecode_size
      ) IS NOT NULL

ORDER BY addr.address;