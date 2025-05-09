/*  -----------------------------------------------------------
    Comprehensive Ethereum-address report (activity < 2017-01-01)
    -----------------------------------------------------------  */

WITH

/* -----------------------------------------------------------------
   1.  Successful CALL traces – exclude delegate/callcode/staticcall
------------------------------------------------------------------*/
cte_traces AS (
    SELECT
        "block_timestamp",
        "block_number",
        "transaction_hash",
        "value",
        "from_address",
        "to_address",
        "gas_used",
        "status"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "block_timestamp" < 1483228800000000                     -- 2017-01-01 in µs
      AND  "status"      = 1
      AND  "trace_type"  = 'call'
      AND  ( "call_type" IS NULL
             OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
),

/* ----------------------- 2. Incoming trace statistics  -----------------------*/
in_stats AS (
    SELECT
        "to_address"                                      AS address,
        COUNT(*)                                          AS in_trace_count,
        COUNT_IF("value" > 0)                             AS in_transfer_count,
        COUNT(DISTINCT "from_address")                    AS in_addr_count,
        SUM("value")                                      AS in_val_sum,
        AVG("value")                                      AS in_avg_amount_wei,
        AVG("gas_used")                                   AS avg_gas_used,
        STDDEV_POP("gas_used")                            AS std_gas_used
    FROM   cte_traces
    GROUP  BY address
),

/* ----------------------- 3. Outgoing trace statistics  -----------------------*/
out_stats AS (
    SELECT
        "from_address"                                    AS address,
        COUNT(*)                                          AS out_trace_count,
        COUNT_IF("value" > 0)                             AS out_transfer_count,
        COUNT(DISTINCT "to_address")                      AS out_addr_count,
        SUM("value")                                      AS out_val_sum,
        AVG("value")                                      AS out_avg_amount_wei
    FROM   cte_traces
    GROUP  BY address
),

/* ----------------------- 4. Hourly-activity & active-days --------------------*/
activity_raw AS (
    SELECT
        addr                                              AS address,
        COUNT(*)                                          AS total_act,
        COUNT(DISTINCT DATE_TRUNC('day',
                     TO_TIMESTAMP_NTZ(ts/1000000)))       AS active_days,
        SUM(COS(2*PI()*hr/24))                            AS sum_cos,
        SUM(SIN(2*PI()*hr/24))                            AS sum_sin
    FROM (
        SELECT  "from_address"          AS addr,
                "block_timestamp"       AS ts,
                DATE_PART('hour',
                  TO_TIMESTAMP_NTZ("block_timestamp"/1000000)) AS hr
        FROM    cte_traces
        UNION ALL
        SELECT  "to_address",
                "block_timestamp",
                DATE_PART('hour',
                  TO_TIMESTAMP_NTZ("block_timestamp"/1000000))
        FROM    cte_traces
        WHERE   "to_address" IS NOT NULL
    ) t
    WHERE  addr IS NOT NULL
    GROUP  BY addr
),
activity AS (
    SELECT
        address,
        active_days,
        CASE WHEN total_act > 24
             THEN SQRT(POWER(sum_cos,2) + POWER(sum_sin,2)) / total_act
        END                                               AS R_active_hour
    FROM   activity_raw
),

/* ----------------------- 5. Transaction-fee (gas) cost ----------------------*/
fee_stats AS (
    SELECT
        "from_address"                                    AS address,
        SUM("gas_price" * "receipt_gas_used")             AS fee_sum
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE  "block_timestamp" < 1483228800000000
      AND  "receipt_status" = 1
    GROUP BY "from_address"
),

/* ----------------------- 6. Mining-reward receipts --------------------------*/
reward_stats AS (
    SELECT
        "to_address"                                      AS address,
        SUM("value")                                      AS reward_sum
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "block_timestamp" < 1483228800000000
      AND  "trace_type" = 'reward'
    GROUP BY "to_address"
),

/* ----------------------- 7. Contract-creation counts ------------------------*/
create_stats AS (
    SELECT
        "from_address"                                    AS address,
        COUNT(*)                                          AS contract_create_count
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "block_timestamp" < 1483228800000000
      AND  "trace_type" = 'create'
    GROUP BY "from_address"
),

/* ----------------------- 8. Failed TX count ---------------------------------*/
failure_stats AS (
    SELECT
        "from_address"                                    AS address,
        COUNT(*)                                          AS failure_count
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE  "block_timestamp" < 1483228800000000
      AND  "receipt_status" = 0
    GROUP BY "from_address"
),

/* ----------------------- 9. Contract byte-code sizes ------------------------*/
bytecode_stats AS (
    SELECT
        "address",
        LENGTH("bytecode")                                AS bytecode_size
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.CONTRACTS
    WHERE  "block_timestamp" < 1483228800000000
),

/* -----------------------10. ERC-20 token IN stats ---------------------------*/
token_in AS (
    SELECT
        "to_address"                                      AS address,
        COUNT(*)                                          AS token_in_tnx,
        COUNT(DISTINCT "token_address")                   AS token_in_type,
        COUNT(DISTINCT "from_address")                    AS token_from_addr
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE  "block_timestamp" < 1483228800000000
    GROUP BY "to_address"
),

/* -----------------------11. ERC-20 token OUT stats --------------------------*/
token_out AS (
    SELECT
        "from_address"                                    AS address,
        COUNT(*)                                          AS token_out_tnx,
        COUNT(DISTINCT "token_address")                   AS token_out_type,
        COUNT(DISTINCT "to_address")                      AS token_to_addr
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE  "block_timestamp" < 1483228800000000
    GROUP BY "from_address"
),

/* -----------------------12. Universe of relevant addresses ------------------*/
addresses AS (
    SELECT DISTINCT address FROM (
          SELECT address FROM in_stats
          UNION SELECT address FROM out_stats
          UNION SELECT address FROM token_in
          UNION SELECT address FROM token_out
          UNION SELECT address FROM reward_stats
          UNION SELECT address FROM create_stats
    )
)

/* -----------------------13. Final consolidated report -----------------------*/
SELECT
    a.address,

    /* ---------- Net balance (ETH) ---------------*/
    ROUND( (COALESCE(in_stats.in_val_sum,0)
          - COALESCE(out_stats.out_val_sum,0)
          - COALESCE(fee_stats.fee_sum,0)) / 1e18 , 4)           AS balance,

    /* ---------- Activity metrics ----------------*/
    activity.R_active_hour,
    activity.active_days,

    /* ---------- Incoming ------------------------*/
    COALESCE(in_stats.in_trace_count,0)                          AS in_trace_count,
    COALESCE(in_stats.in_addr_count,0)                           AS in_addr_count,
    COALESCE(in_stats.in_transfer_count,0)                       AS in_transfer_count,
    ROUND(COALESCE(in_stats.in_avg_amount_wei,0)/1e18 ,4)        AS in_avg_amount,
    COALESCE(in_stats.avg_gas_used,0)                            AS avg_gas_used,
    COALESCE(in_stats.std_gas_used,0)                            AS std_gas_used,

    /* ---------- Outgoing ------------------------*/
    COALESCE(out_stats.out_trace_count,0)                        AS out_trace_count,
    COALESCE(out_stats.out_addr_count,0)                         AS out_addr_count,
    COALESCE(out_stats.out_transfer_count,0)                     AS out_transfer_count,
    ROUND(COALESCE(out_stats.out_avg_amount_wei,0)/1e18 ,4)      AS out_avg_amount,

    /* ---------- Token transfers -----------------*/
    COALESCE(token_in.token_in_tnx,0)                            AS token_in_tnx,
    COALESCE(token_in.token_in_type,0)                           AS token_in_type,
    COALESCE(token_in.token_from_addr,0)                         AS token_from_addr,
    COALESCE(token_out.token_out_tnx,0)                          AS token_out_tnx,
    COALESCE(token_out.token_out_type,0)                         AS token_out_type,
    COALESCE(token_out.token_to_addr,0)                          AS token_to_addr,

    /* ---------- Rewards / contracts / failures --*/
    ROUND(COALESCE(reward_stats.reward_sum,0) / 1e18 ,4)         AS reward_amount,
    COALESCE(create_stats.contract_create_count,0)               AS contract_create_count,
    COALESCE(failure_stats.failure_count,0)                      AS failure_count,
    bytecode_stats.bytecode_size

FROM   addresses            a
LEFT   JOIN in_stats        ON a.address = in_stats.address
LEFT   JOIN out_stats       ON a.address = out_stats.address
LEFT   JOIN activity        ON a.address = activity.address
LEFT   JOIN fee_stats       ON a.address = fee_stats.address
LEFT   JOIN reward_stats    ON a.address = reward_stats.address
LEFT   JOIN create_stats    ON a.address = create_stats.address
LEFT   JOIN failure_stats   ON a.address = failure_stats.address
LEFT   JOIN bytecode_stats  ON a.address = bytecode_stats."address"
LEFT   JOIN token_in        ON a.address = token_in.address
LEFT   JOIN token_out       ON a.address = token_out.address

ORDER  BY balance DESC NULLS LAST;