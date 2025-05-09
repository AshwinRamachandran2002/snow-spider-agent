/* -------------------------------------------------------------------------
   Comprehensive Ethereum-address report for all activity prior to 1-Jan-2017
   ------------------------------------------------------------------------- */
WITH
/* ------------ constant cut-off ( 2017-01-01 00:00:00 UTC, ns ) ------------ */
cutoff AS (
  SELECT 1483228800000000000::NUMBER AS "ts"
),

/* ----------------------------- base TX set  ------------------------------ */
base_tx AS (
  SELECT
      "hash",
      "block_timestamp",
      "from_address",
      "to_address",
      "value",
      "gas_price",
      "receipt_gas_used"
  FROM  ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS", cutoff
  WHERE "block_timestamp" < cutoff."ts"
    AND "receipt_status" = 1                -- successful only
),

/* ---------------- incoming / outgoing transaction aggregates ------------- */
in_tx AS (
  SELECT
      "to_address"                               AS "address",
      COUNT(*)                                   AS "in_trace_count",
      COUNT(DISTINCT "from_address")             AS "in_addr_count",
      SUM( CASE WHEN "value" > 0 THEN 1 ELSE 0 END )          AS "in_transfer_count",
      AVG( "value" ) / 1e18                      AS "in_avg_amount",
      SUM( "value" )                             AS "total_in_value"
  FROM base_tx
  WHERE "to_address" IS NOT NULL
  GROUP BY "to_address"
),

out_tx AS (
  SELECT
      "from_address"                             AS "address",
      COUNT(*)                                   AS "out_trace_count",
      COUNT(DISTINCT "to_address")               AS "out_addr_count",
      SUM( CASE WHEN "value" > 0 THEN 1 ELSE 0 END )          AS "out_transfer_count",
      AVG( "value" ) / 1e18                      AS "out_avg_amount",
      SUM( "value" )                             AS "total_out_value",
      SUM( "gas_price" * "receipt_gas_used" )    AS "total_gas_fee"
  FROM base_tx
  WHERE "from_address" IS NOT NULL
  GROUP BY "from_address"
),

/* ---------------------------- token transfers ---------------------------- */
token_in AS (
  SELECT
      "to_address"                               AS "address",
      COUNT(*)                                   AS "token_in_tnx",
      COUNT(DISTINCT "token_address")            AS "token_in_type",
      COUNT(DISTINCT "from_address")             AS "token_from_addr"
  FROM  ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS", cutoff
  WHERE "block_timestamp" < cutoff."ts"
  GROUP BY "to_address"
),

token_out AS (
  SELECT
      "from_address"                             AS "address",
      COUNT(*)                                   AS "token_out_tnx",
      COUNT(DISTINCT "token_address")            AS "token_out_type",
      COUNT(DISTINCT "to_address")               AS "token_to_addr"
  FROM  ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS", cutoff
  WHERE "block_timestamp" < cutoff."ts"
  GROUP BY "from_address"
),

/* ----------------------------- mining rewards ---------------------------- */
rewards AS (
  SELECT
      "to_address"                               AS "address",
      SUM("value")                               AS "reward_wei"
  FROM  ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", cutoff
  WHERE "block_timestamp" < cutoff."ts"
    AND "trace_type" = 'reward'
  GROUP BY "to_address"
),

/* --------------------------- contract creations -------------------------- */
contract_creates AS (
  SELECT
      "from_address"                             AS "address",
      COUNT(*)                                   AS "contract_create_count"
  FROM  ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", cutoff
  WHERE "block_timestamp" < cutoff."ts"
    AND "trace_type" = 'create'
  GROUP BY "from_address"
),

/* --------------------------- failed transactions ------------------------- */
failures AS (
  SELECT
      "from_address"                             AS "address",
      COUNT(*)                                   AS "failure_count"
  FROM  ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS", cutoff
  WHERE "block_timestamp" < cutoff."ts"
    AND "receipt_status" = 0
  GROUP BY "from_address"
),

/* ------------------------- byte-code length for contracts --------------- */
bytecodes AS (
  SELECT
      "address",
      LENGTH("bytecode")                         AS "bytecode_size"
  FROM  ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."CONTRACTS", cutoff
  WHERE "block_timestamp" < cutoff."ts"
),

/* ---------------- average / stdev gas used on successful calls ----------- */
gas_stats AS (
  SELECT
      "to_address"                               AS "address",
      AVG("gas_used")                            AS "avg_gas_used",
      STDDEV_SAMP("gas_used")                    AS "std_gas_used"
  FROM  ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", cutoff
  WHERE "block_timestamp" < cutoff."ts"
    AND "trace_type" = 'call'
    AND COALESCE("call_type",'') NOT IN ('delegatecall','callcode','staticcall')
    AND "status" = 1
    AND "to_address" IS NOT NULL
  GROUP BY "to_address"
),

/* --------------------------- activity statistics ------------------------- */
activity AS (
  SELECT
      "addr"                                     AS "address",
      COUNT( DISTINCT DATE_TRUNC('day', "ts") )  AS "active_days",
      /*  R = √( (Σcosθ)^2 + (Σsinθ)^2 ) / n  */
      SQRT( POWER( SUM( COS("theta") ), 2 )
          + POWER( SUM( SIN("theta") ), 2 ) ) / COUNT(*)  AS "R_active_hour"
  FROM (
        SELECT
            /* choose whichever side supplies the address */
            CASE
                WHEN "from_address" IS NOT NULL THEN "from_address"
                ELSE "to_address"
            END                                   AS "addr",
            TO_TIMESTAMP_NTZ( "block_timestamp" / 1000000000 )  AS "ts",
            MOD( FLOOR( ("block_timestamp" / 1000000000) / 3600 ), 24 ) AS "hr",
            2 * PI() * MOD( FLOOR( ("block_timestamp" / 1000000000) / 3600 ), 24 ) / 24 AS "theta"
        FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS", cutoff
        WHERE "block_timestamp" < cutoff."ts"
  ) sub
  GROUP BY "addr"
),

/* --------------------------- master address list ------------------------ */
all_addresses AS (
  SELECT "address" FROM in_tx UNION
  SELECT "address" FROM out_tx UNION
  SELECT "address" FROM token_in UNION
  SELECT "address" FROM token_out UNION
  SELECT "address" FROM rewards UNION
  SELECT "address" FROM contract_creates
)

/* ------------------------------ final report ----------------------------- */
SELECT
    a."address",

    /* ---------------------------- balances ------------------------------ */
    (  COALESCE(in_tx."total_in_value",0)
     - COALESCE(out_tx."total_out_value",0)
     - COALESCE(out_tx."total_gas_fee",0)
     + COALESCE(rewards."reward_wei",0) ) / 1e18                AS "balance",

    /* activity metrics */
    COALESCE(activity."R_active_hour",0)                         AS "R_active_hour",
    COALESCE(activity."active_days",0)                           AS "active_days",

    /* incoming TX metrics */
    COALESCE(in_tx."in_trace_count",0)                           AS "in_trace_count",
    COALESCE(in_tx."in_addr_count",0)                            AS "in_addr_count",
    COALESCE(in_tx."in_transfer_count",0)                        AS "in_transfer_count",
    COALESCE(in_tx."in_avg_amount",0)                            AS "in_avg_amount",
    COALESCE(gas_stats."avg_gas_used",0)                         AS "avg_gas_used",
    COALESCE(gas_stats."std_gas_used",0)                         AS "std_gas_used",

    /* outgoing TX metrics */
    COALESCE(out_tx."out_trace_count",0)                         AS "out_trace_count",
    COALESCE(out_tx."out_addr_count",0)                          AS "out_addr_count",
    COALESCE(out_tx."out_transfer_count",0)                      AS "out_transfer_count",
    COALESCE(out_tx."out_avg_amount",0)                          AS "out_avg_amount",

    /* token metrics */
    COALESCE(token_in."token_in_tnx",0)                          AS "token_in_tnx",
    COALESCE(token_in."token_in_type",0)                         AS "token_in_type",
    COALESCE(token_in."token_from_addr",0)                       AS "token_from_addr",
    COALESCE(token_out."token_out_tnx",0)                        AS "token_out_tnx",
    COALESCE(token_out."token_out_type",0)                       AS "token_out_type",
    COALESCE(token_out."token_to_addr",0)                        AS "token_to_addr",

    /* mining rewards & contract creation */
    COALESCE(rewards."reward_wei",0) / 1e18                      AS "reward_amount",
    COALESCE(contract_creates."contract_create_count",0)         AS "contract_create_count",

    /* failures & byte-code info */
    COALESCE(failures."failure_count",0)                         AS "failure_count",
    COALESCE(bytecodes."bytecode_size",0)                        AS "bytecode_size"

FROM  all_addresses                   AS a
LEFT  JOIN in_tx                      ON a."address" = in_tx."address"
LEFT  JOIN out_tx                     ON a."address" = out_tx."address"
LEFT  JOIN token_in                   ON a."address" = token_in."address"
LEFT  JOIN token_out                  ON a."address" = token_out."address"
LEFT  JOIN rewards                    ON a."address" = rewards."address"
LEFT  JOIN contract_creates           ON a."address" = contract_creates."address"
LEFT  JOIN failures                   ON a."address" = failures."address"
LEFT  JOIN bytecodes                  ON a."address" = bytecodes."address"
LEFT  JOIN activity                   ON a."address" = activity."address"
LEFT  JOIN gas_stats                  ON a."address" = gas_stats."address"
ORDER BY "balance" DESC NULLS LAST;