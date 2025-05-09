/* ---------------------------------------------------------------------
   Comprehensive Ethereum-address report (activity < 01-Jan-2017)
   All ETH-denominated amounts are divided by 1e18 (Wei → Ether)
   Snowflake dialect
------------------------------------------------------------------------ */

WITH
/* ---------- constant cut-off in micro-seconds ------------------------ */
CONST AS (
    SELECT 1483228800000000::NUMBER AS cutoff
),

/* ---------- traces (value-transferring calls only) ------------------- */
FILTERED_TRACES AS (
    SELECT t.*
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES t , CONST
    WHERE  t."block_timestamp" < cutoff
      AND  t."trace_type" = 'call'
      AND (t."call_type" IS NULL
           OR t."call_type" NOT IN ('delegatecall','callcode','staticcall'))
),

/* ---------- activity rows (both directions) -------------------------- */
ACTIVITY_ROWS AS (
    SELECT "from_address" AS address , "block_timestamp" FROM FILTERED_TRACES
    UNION ALL
    SELECT "to_address"   AS address , "block_timestamp" FROM FILTERED_TRACES
),

/* ---------- per-address activity aggregates -------------------------- */
ACTIVITY_AGG AS (
    SELECT
        address,
        COUNT(*)                                                   AS activity_count,
        COUNT(DISTINCT DATE_TRUNC('day',
              TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)))          AS active_days,
        SUM(COS(2 * PI() *
            (FLOOR(MOD("block_timestamp",86400000000) / 3600000000)) / 24)) AS sum_cos,
        SUM(SIN(2 * PI() *
            (FLOOR(MOD("block_timestamp",86400000000) / 3600000000)) / 24)) AS sum_sin
    FROM ACTIVITY_ROWS
    GROUP BY address
),
ACTIVITY_METRICS AS (
    SELECT
        address,
        CASE WHEN activity_count > 24
             THEN SQRT(POWER(sum_cos,2) + POWER(sum_sin,2)) / activity_count
        END                                                        AS R_active_hour,
        active_days
    FROM ACTIVITY_AGG
),

/* ---------- incoming trace statistics -------------------------------- */
IN_TRACES AS (
    SELECT
        "to_address"                               AS address,
        COUNT(*)                                   AS in_trace_count,
        COUNT(DISTINCT "from_address")             AS in_addr_count,
        COUNT_IF("value" <> 0)                     AS in_transfer_count,
        AVG("value")                               AS in_avg_value,
        AVG("gas_used")                            AS avg_gas_used,
        STDDEV_SAMP("gas_used")                    AS std_gas_used
    FROM FILTERED_TRACES
    GROUP BY "to_address"
),

/* ---------- outgoing trace statistics -------------------------------- */
OUT_TRACES AS (
    SELECT
        "from_address"                             AS address,
        COUNT(*)                                   AS out_trace_count,
        COUNT(DISTINCT "to_address")               AS out_addr_count,
        COUNT_IF("value" <> 0)                     AS out_transfer_count,
        AVG("value")                               AS out_avg_value
    FROM FILTERED_TRACES
    GROUP BY "from_address"
),

/* ---------- ERC-20 token transfers before cut-off -------------------- */
FILTERED_TOK_XFERS AS (
    SELECT tf.*
    FROM  ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS tf , CONST
    WHERE tf."block_timestamp" < cutoff
),
TOKEN_IN AS (
    SELECT
        "to_address"                               AS address,
        COUNT(*)                                   AS token_in_tnx,
        COUNT(DISTINCT "token_address")            AS token_in_type,
        COUNT(DISTINCT "from_address")             AS token_from_addr
    FROM  FILTERED_TOK_XFERS
    GROUP BY "to_address"
),
TOKEN_OUT AS (
    SELECT
        "from_address"                             AS address,
        COUNT(*)                                   AS token_out_tnx,
        COUNT(DISTINCT "token_address")            AS token_out_type,
        COUNT(DISTINCT "to_address")               AS token_to_addr
    FROM  FILTERED_TOK_XFERS
    GROUP BY "from_address"
),

/* ---------- mining rewards ------------------------------------------- */
REWARDS AS (
    SELECT
        "to_address"                               AS address,
        SUM("value") / 1e18                        AS reward_amount
    FROM  ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES tr , CONST
    WHERE tr."block_timestamp" < cutoff
      AND tr."trace_type" = 'reward'
    GROUP BY "to_address"
),

/* ---------- contract creation count ---------------------------------- */
CONTRACTS_CREATED AS (
    SELECT
        "from_address"                             AS address,
        COUNT(*)                                   AS contract_create_count
    FROM  ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES tr , CONST
    WHERE tr."block_timestamp" < cutoff
      AND tr."trace_type" = 'create'
    GROUP BY "from_address"
),

/* ---------- failed transactions -------------------------------------- */
FAILURES AS (
    SELECT
        "from_address"                             AS address,
        COUNT(*)                                   AS failure_count
    FROM  ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS tx , CONST
    WHERE tx."block_timestamp" < cutoff
      AND tx."receipt_status" = 0
    GROUP BY "from_address"
),

/* ---------- successful tx (for balance) ------------------------------ */
TX_SUCCESS AS (
    SELECT tx.*
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS tx , CONST
    WHERE  tx."block_timestamp" < cutoff
      AND  tx."receipt_status" = 1
),
ETH_IN AS (
    SELECT "to_address" AS address,
           SUM("value") AS eth_in
    FROM  TX_SUCCESS
    GROUP BY "to_address"
),
ETH_OUT_FEE AS (
    SELECT "from_address" AS address,
           SUM("value")                              AS eth_out,
           SUM("gas_price" * "receipt_gas_used")     AS fees
    FROM  TX_SUCCESS
    GROUP BY "from_address"
),
BALANCE AS (
    SELECT
        COALESCE(ei.address, eo.address)                                AS address,
        (COALESCE(ei.eth_in,0) - COALESCE(eo.eth_out,0)
         - COALESCE(eo.fees,0)) / 1e18                                  AS balance
    FROM ETH_IN ei
    FULL JOIN ETH_OUT_FEE eo ON ei.address = eo.address
),

/* ---------- byte-code sizes for contracts ---------------------------- */
BYTECODE AS (
    SELECT
        "address"      AS address,
        LENGTH("bytecode")                        AS bytecode_size
    FROM  ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.CONTRACTS c , CONST
    WHERE c."block_timestamp" < cutoff
),

/* ---------- universe of addresses ------------------------------------ */
ALL_ADDRESSES AS (
    SELECT address FROM ACTIVITY_AGG
    UNION SELECT address FROM TOKEN_IN
    UNION SELECT address FROM TOKEN_OUT
    UNION SELECT address FROM REWARDS
    UNION SELECT address FROM CONTRACTS_CREATED
    UNION SELECT address FROM FAILURES
    UNION SELECT address FROM BALANCE
    UNION SELECT address FROM BYTECODE
)

/* =================== final report ==================================== */
SELECT
    a.address,

    COALESCE(bal.balance,0)                             AS balance,

    act.R_active_hour,
    act.active_days,

    in_t.in_trace_count,
    in_t.in_addr_count,
    in_t.in_transfer_count,
    (in_t.in_avg_value / 1e18)      AS in_avg_amount,
    in_t.avg_gas_used               AS avg_gas_used,
    in_t.std_gas_used               AS std_gas_used,

    out_t.out_trace_count,
    out_t.out_addr_count,
    out_t.out_transfer_count,
    (out_t.out_avg_value / 1e18)    AS out_avg_amount,

    tin.token_in_tnx,
    tin.token_in_type,
    tin.token_from_addr,
    tout.token_out_tnx,
    tout.token_out_type,
    tout.token_to_addr,

    rw.reward_amount,
    cc.contract_create_count,
    fl.failure_count,
    bc.bytecode_size

FROM  ALL_ADDRESSES            a
LEFT  JOIN BALANCE            bal  ON a.address = bal.address
LEFT  JOIN ACTIVITY_METRICS   act  ON a.address = act.address
LEFT  JOIN IN_TRACES          in_t ON a.address = in_t.address
LEFT  JOIN OUT_TRACES         out_t ON a.address = out_t.address
LEFT  JOIN TOKEN_IN           tin  ON a.address = tin.address
LEFT  JOIN TOKEN_OUT          tout ON a.address = tout.address
LEFT  JOIN REWARDS            rw   ON a.address = rw.address
LEFT  JOIN CONTRACTS_CREATED  cc   ON a.address = cc.address
LEFT  JOIN FAILURES           fl   ON a.address = fl.address
LEFT  JOIN BYTECODE           bc   ON a.address = bc.address

/* --- ensure at least some transactional footprint -------------------- */
WHERE act.active_days      IS NOT NULL
   OR in_t.in_trace_count  IS NOT NULL
   OR out_t.out_trace_count IS NOT NULL;