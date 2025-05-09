/* -----------------------------------------------------------
   Comprehensive address-level report for all Ethereum
   addresses with any on-chain activity BEFORE 2017-01-01
   (timestamp 1483228800000000   – micro-seconds).
   All ETH figures are shown in standard units (÷ 10¹⁸).
----------------------------------------------------------- */
WITH
/* --------------- constant cut-off ------------------------ */
c_constants AS (
    SELECT 1483228800000000::NUMBER AS cutoff_ts
),

/* --------------- universe of early addresses ------------- */
early_addresses AS (
    SELECT DISTINCT addr
    FROM (
          /* TRANSACTIONS */
          SELECT "from_address" AS addr
          FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS", c_constants
          WHERE "block_timestamp" < cutoff_ts AND "from_address" IS NOT NULL
          UNION
          SELECT "to_address" AS addr
          FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS", c_constants
          WHERE "block_timestamp" < cutoff_ts AND "to_address" IS NOT NULL
          /* TRACES (all types) */
          UNION
          SELECT "from_address" AS addr
          FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", c_constants
          WHERE "block_timestamp" < cutoff_ts AND "from_address" IS NOT NULL
          UNION
          SELECT "to_address" AS addr
          FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", c_constants
          WHERE "block_timestamp" < cutoff_ts AND "to_address" IS NOT NULL
          /* TOKEN_TRANSFERS */
          UNION
          SELECT "from_address" AS addr
          FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS", c_constants
          WHERE "block_timestamp" < cutoff_ts AND "from_address" IS NOT NULL
          UNION
          SELECT "to_address" AS addr
          FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS", c_constants
          WHERE "block_timestamp" < cutoff_ts AND "to_address" IS NOT NULL
          /* CONTRACTS already created */
          UNION
          SELECT "address" AS addr
          FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."CONTRACTS", c_constants
          WHERE "block_timestamp" < cutoff_ts AND "address" IS NOT NULL
    )
),

/* --------------- successful externally-visible calls ------ */
traces_filtered AS (
    SELECT *
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", c_constants
    WHERE "block_timestamp" < cutoff_ts
      AND "trace_type" = 'call'
      AND "status" = 1
      AND COALESCE("call_type",'call') NOT IN ('delegatecall','callcode','staticcall')
),

/* --------------- incoming trace aggregates --------------- */
trace_in AS (
    SELECT
        "to_address"                                    AS address,
        COUNT(*)                                        AS in_trace_count,
        COUNT(DISTINCT "from_address")                  AS in_addr_count,
        SUM(CASE WHEN "value" > 0 THEN 1 ELSE 0 END)    AS in_transfer_count,
        AVG(CASE WHEN "value" > 0 THEN "value" END)/1e18           AS in_avg_amount,
        AVG("gas_used")                                 AS avg_gas_used,
        STDDEV_SAMP("gas_used")                         AS std_gas_used
    FROM traces_filtered
    GROUP BY "to_address"
),

/* --------------- outgoing trace aggregates --------------- */
trace_out AS (
    SELECT
        "from_address"                                  AS address,
        COUNT(*)                                        AS out_trace_count,
        COUNT(DISTINCT "to_address")                    AS out_addr_count,
        SUM(CASE WHEN "value" > 0 THEN 1 ELSE 0 END)    AS out_transfer_count,
        AVG(CASE WHEN "value" > 0 THEN "value" END)/1e18          AS out_avg_amount
    FROM traces_filtered
    GROUP BY "from_address"
),

/* --------------- hourly activity & active days ----------- */
activity AS (
    SELECT
        addr                                            AS address,
        COUNT(*)                                        AS act_count,
        COUNT(DISTINCT DATE_TRUNC('day', ts))           AS active_days,
        SUM(COS(2*PI()*hr/24))                          AS cos_sum,
        SUM(SIN(2*PI()*hr/24))                          AS sin_sum
    FROM (
        SELECT
            CASE
                WHEN t."from_address" = ea.addr THEN t."from_address"
                ELSE t."to_address"
            END                                         AS addr,
            TO_TIMESTAMP(t."block_timestamp"/1e6)       AS ts,
            EXTRACT(hour FROM TO_TIMESTAMP(t."block_timestamp"/1e6)) AS hr
        FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES" t
        JOIN early_addresses ea
          ON  t."from_address" = ea.addr
          OR  t."to_address"   = ea.addr
        , c_constants
        WHERE t."block_timestamp" < cutoff_ts
    )
    GROUP BY addr
),
activity_final AS (
    SELECT
        address,
        CASE
            WHEN act_count > 24
            THEN SQRT(POWER(cos_sum,2) + POWER(sin_sum,2)) / act_count
        END                                             AS R_active_hour,
        active_days
    FROM activity
),

/* --------------- ETH received / sent --------------------- */
traces_balance AS (
    SELECT
        address,
        SUM(received) AS received_wei,
        SUM(sent)     AS sent_wei
    FROM (
        SELECT "to_address"   AS address, SUM("value") AS received, 0 AS sent
        FROM traces_filtered GROUP BY "to_address"
        UNION ALL
        SELECT "from_address" AS address, 0 AS received, SUM("value") AS sent
        FROM traces_filtered GROUP BY "from_address"
    )
    GROUP BY address
),

/* --------------- transaction fees (successful only) ------ */
tx_fees AS (
    SELECT
        "from_address" AS address,
        SUM(COALESCE("gas_price",0) * COALESCE("receipt_gas_used",0)) AS fee_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS", c_constants
    WHERE "block_timestamp" < cutoff_ts
      AND "receipt_status" = 1
      AND "from_address" IS NOT NULL
    GROUP BY "from_address"
),
balance_final AS (
    SELECT
        ea.addr AS address,
        ( COALESCE(tb.received_wei,0)
        - COALESCE(tb.sent_wei,0)
        - COALESCE(tf.fee_wei,0) ) / 1e18             AS balance
    FROM early_addresses ea
    LEFT JOIN traces_balance tb ON ea.addr = tb.address
    LEFT JOIN tx_fees       tf ON ea.addr = tf.address
),

/* --------------- token transfer metrics ------------------ */
token_in AS (
    SELECT
        "to_address"                       AS address,
        COUNT(*)                           AS token_in_tnx,
        COUNT(DISTINCT "token_address")    AS token_in_type,
        COUNT(DISTINCT "from_address")     AS token_from_addr
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS", c_constants
    WHERE "block_timestamp" < cutoff_ts
    GROUP BY "to_address"
),
token_out AS (
    SELECT
        "from_address"                     AS address,
        COUNT(*)                           AS token_out_tnx,
        COUNT(DISTINCT "token_address")    AS token_out_type,
        COUNT(DISTINCT "to_address")       AS token_to_addr
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS", c_constants
    WHERE "block_timestamp" < cutoff_ts
    GROUP BY "from_address"
),

/* --------------- mining rewards -------------------------- */
rewards AS (
    SELECT
        "to_address" AS address,
        SUM("value")/1e18 AS reward_amount
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", c_constants
    WHERE "trace_type" = 'reward'
      AND "block_timestamp" < cutoff_ts
    GROUP BY "to_address"
),

/* --------------- contract creation count ----------------- */
contract_create AS (
    SELECT
        "from_address" AS address,
        COUNT(*)       AS contract_create_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", c_constants
    WHERE "trace_type" = 'create'
      AND "block_timestamp" < cutoff_ts
    GROUP BY "from_address"
),

/* --------------- failed transactions --------------------- */
failures AS (
    SELECT
        "from_address" AS address,
        COUNT(*)       AS failure_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS", c_constants
    WHERE "block_timestamp" < cutoff_ts
      AND "receipt_status" = 0
    GROUP BY "from_address"
),

/* --------------- byte-code sizes ------------------------- */
bytecode_sizes AS (
    SELECT
        "address" AS address,
        (LENGTH("bytecode") - 2) AS bytecode_size      -- strip leading '0x'
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."CONTRACTS", c_constants
    WHERE "block_timestamp" < cutoff_ts
)

/* ===================== final report ====================== */
SELECT
    ea.addr                             AS "address",
    bf.balance                          AS "balance",
    af.R_active_hour                    AS "R_active_hour",
    af.active_days                      AS "active_days",
    tin.in_trace_count                  AS "in_trace_count",
    tin.in_addr_count                   AS "in_addr_count",
    tin.in_transfer_count               AS "in_transfer_count",
    tin.in_avg_amount                   AS "in_avg_amount",
    tin.avg_gas_used                    AS "avg_gas_used",
    tin.std_gas_used                    AS "std_gas_used",
    tout.out_trace_count                AS "out_trace_count",
    tout.out_addr_count                 AS "out_addr_count",
    tout.out_transfer_count             AS "out_transfer_count",
    tout.out_avg_amount                 AS "out_avg_amount",
    tk_in.token_in_tnx                  AS "token_in_tnx",
    tk_in.token_in_type                 AS "token_in_type",
    tk_in.token_from_addr               AS "token_from_addr",
    tk_out.token_out_tnx                AS "token_out_tnx",
    tk_out.token_out_type               AS "token_out_type",
    tk_out.token_to_addr                AS "token_to_addr",
    rw.reward_amount                    AS "reward_amount",
    cc.contract_create_count            AS "contract_create_count",
    fl.failure_count                    AS "failure_count",
    bc.bytecode_size                    AS "bytecode_size"
FROM early_addresses ea
LEFT JOIN balance_final   bf  ON ea.addr = bf.address
LEFT JOIN activity_final  af  ON ea.addr = af.address
LEFT JOIN trace_in        tin ON ea.addr = tin.address
LEFT JOIN trace_out       tout ON ea.addr = tout.address
LEFT JOIN token_in        tk_in ON ea.addr = tk_in.address
LEFT JOIN token_out       tk_out ON ea.addr = tk_out.address
LEFT JOIN rewards         rw  ON ea.addr = rw.address
LEFT JOIN contract_create cc  ON ea.addr = cc.address
LEFT JOIN failures        fl  ON ea.addr = fl.address
LEFT JOIN bytecode_sizes  bc  ON ea.addr = bc.address
/* keep only addresses with real pre-2017 activity */
WHERE (COALESCE(tin.in_trace_count,0)
     + COALESCE(tout.out_trace_count,0)
     + COALESCE(tk_in.token_in_tnx,0)
     + COALESCE(tk_out.token_out_tnx,0)
     + COALESCE(cc.contract_create_count,0)
     + COALESCE(rw.reward_amount,0)) > 0
ORDER BY bf.balance DESC NULLS LAST;