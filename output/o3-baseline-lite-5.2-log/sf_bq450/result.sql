WITH
/* -------------------------------------------------
   1.  cut‑off time : 01‑Jan‑2017 (unix µ‑seconds)
------------------------------------------------- */
constants AS ( SELECT 1483228800000000 AS cutoff ),

/* -------------------------------------------------
   2.  Successful transactions (only receipt_status = 1)
------------------------------------------------- */
txs AS (
    SELECT
        "hash",
        "from_address",
        "to_address",
        "value"                   AS wei_value,
        "receipt_gas_used",
        "gas_price",
        "block_timestamp"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS", constants
    WHERE "block_timestamp" < cutoff
      AND ("receipt_status" = 1 OR "receipt_status" IS NULL)          -- treat missing status = success
),

/* ---- incoming / outgoing eth (Wei) & fees ------------------------ */
txs_in  AS (
    SELECT "to_address"   AS address,
           SUM(wei_value) AS eth_in_wei
    FROM txs
    WHERE "to_address" IS NOT NULL
    GROUP BY address
),
txs_out AS (
    SELECT "from_address"                                     AS address,
           SUM(wei_value)                                     AS eth_out_wei,
           SUM("receipt_gas_used" * "gas_price")              AS fee_wei
    FROM txs
    WHERE "from_address" IS NOT NULL
    GROUP BY address
),

/* -------------------------------------------------
   3.  Reward traces (mining / uncle)
------------------------------------------------- */
reward_stats AS (
    SELECT "to_address"     AS address,
           SUM("value")/1e18   AS reward_amount      -- already converted to Ether
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", constants
    WHERE "block_timestamp" < cutoff
      AND "trace_type" = 'reward'
    GROUP BY address
),

/* -------------------------------------------------
   4.  Net balance = in  –  out  –  fees + rewards
------------------------------------------------- */
balance AS (
    SELECT
        COALESCE(tin.address, tout.address, reward.address)                    AS address,
        (  COALESCE(tin.eth_in_wei ,0)
         - COALESCE(tout.eth_out_wei,0)
         - COALESCE(tout.fee_wei    ,0)
         + COALESCE(reward.reward_amount*1e18,0)          /* back to Wei for algebra */
        ) / 1e18                                             AS balance
    FROM txs_in  tin
    FULL JOIN txs_out  tout     USING(address)
    FULL JOIN reward_stats reward USING(address)
),

/* -------------------------------------------------
   5.  Traces – successful call / create / reward
------------------------------------------------- */
traces_ok AS (
    SELECT *
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", constants
    WHERE "block_timestamp" < cutoff
      AND (
            ("trace_type" = 'call'
                 AND "status" = 1
                 AND ( "call_type" IS NULL
                        OR "call_type" NOT IN ('delegatecall','callcode','staticcall')))
         OR  "trace_type" IN ('create','reward')
          )
),

/* -------- hourly activity (all directions) ----------------------- */
hourly_events AS (
    SELECT "from_address" AS address, "block_timestamp"
    FROM traces_ok WHERE "from_address" IS NOT NULL
    UNION ALL
    SELECT "to_address"   AS address, "block_timestamp"
    FROM traces_ok WHERE "to_address"   IS NOT NULL
),
hourly_stats AS (
    SELECT
        address,
        COUNT(*)                                                   AS n_events,
        COUNT(DISTINCT DATE(TO_TIMESTAMP("block_timestamp"/1000000))) AS active_days,
        SUM(COS(2*PI()*DATE_PART('HOUR', TO_TIMESTAMP("block_timestamp"/1000000))/24)) AS sum_cos,
        SUM(SIN(2*PI()*DATE_PART('HOUR', TO_TIMESTAMP("block_timestamp"/1000000))/24)) AS sum_sin
    FROM hourly_events
    GROUP BY address
),
hourly_metric AS (
    SELECT
        address,
        active_days,
        CASE WHEN n_events > 24 THEN
                 SQRT(sum_cos*sum_cos + sum_sin*sum_sin) / n_events
             ELSE NULL
        END                                                        AS R_active_hour
    FROM hourly_stats
),

/* -------- incoming / outgoing trace statistics ------------------ */
trace_in AS (
    SELECT
        "to_address"                                       AS address,
        COUNT(*)                                           AS in_trace_count,
        COUNT(DISTINCT "from_address")                     AS in_addr_count,
        SUM(CASE WHEN "value" > 0 THEN 1 ELSE 0 END)       AS in_transfer_count,
        AVG(CASE WHEN "value" > 0 THEN "value" END)/1e18   AS in_avg_amount
    FROM traces_ok
    WHERE "to_address" IS NOT NULL
    GROUP BY address
),
trace_out AS (
    SELECT
        "from_address"                                     AS address,
        COUNT(*)                                           AS out_trace_count,
        COUNT(DISTINCT "to_address")                       AS out_addr_count,
        SUM(CASE WHEN "value" > 0 THEN 1 ELSE 0 END)       AS out_transfer_count,
        AVG(CASE WHEN "value" > 0 THEN "value" END)/1e18   AS out_avg_amount
    FROM traces_ok
    WHERE "from_address" IS NOT NULL
    GROUP BY address
),
/* ---- gas stats on incoming successful CALLs -------------------- */
gas_in AS (
    SELECT
        "to_address"                         AS address,
        AVG("gas_used")                      AS avg_gas_used,
        STDDEV_SAMP("gas_used")              AS std_gas_used
    FROM traces_ok
    WHERE "trace_type" = 'call'
      AND "to_address" IS NOT NULL
    GROUP BY address
),

/* -------------------------------------------------
   6.  ERC‑20 token transfers
------------------------------------------------- */
token_tr AS (
    SELECT *
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS", constants
    WHERE "block_timestamp" < cutoff
),
token_in AS (
    SELECT
        "to_address"                             AS address,
        COUNT(*)                                 AS token_in_tnx,
        COUNT(DISTINCT "token_address")          AS token_in_type,
        COUNT(DISTINCT "from_address")           AS token_from_addr
    FROM token_tr
    GROUP BY address
),
token_out AS (
    SELECT
        "from_address"                           AS address,
        COUNT(*)                                 AS token_out_tnx,
        COUNT(DISTINCT "token_address")          AS token_out_type,
        COUNT(DISTINCT "to_address")             AS token_to_addr
    FROM token_tr
    GROUP BY address
),

/* -------------------------------------------------
   7.  Contract creations, failures, byte‑code size
------------------------------------------------- */
create_stats AS (
    SELECT
        "from_address"        AS address,
        COUNT(*)              AS contract_create_count
    FROM traces_ok
    WHERE "trace_type" = 'create'
    GROUP BY address
),
failure_stats AS (
    SELECT
        "from_address"        AS address,
        COUNT(*)              AS failure_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", constants
    WHERE "block_timestamp" < cutoff
      AND "status" = 0
      AND "from_address" IS NOT NULL
    GROUP BY address
),
created_contracts AS (
    SELECT
        "from_address"  AS creator,
        "to_address"    AS contract_addr
    FROM traces_ok
    WHERE "trace_type" = 'create'
),
bytecode_stats AS (
    SELECT
        creator                         AS address,
        SUM(LENGTH(c."bytecode"))       AS bytecode_size
    FROM created_contracts
    JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."CONTRACTS" c
          ON c."address" = contract_addr
         AND c."block_timestamp" < 1483228800000000
    GROUP BY creator
),

/* -------------------------------------------------
   8.  Address universe (any activity before cut‑off)
------------------------------------------------- */
all_addresses AS (
    SELECT DISTINCT address FROM (
        SELECT address FROM balance
        UNION SELECT address FROM hourly_metric
        UNION SELECT address FROM trace_in
        UNION SELECT address FROM trace_out
        UNION SELECT address FROM gas_in
        UNION SELECT address FROM token_in
        UNION SELECT address FROM token_out
        UNION SELECT address FROM reward_stats
        UNION SELECT address FROM create_stats
        UNION SELECT address FROM failure_stats
        UNION SELECT address FROM bytecode_stats
    )
)

/* -------------------------------------------------
   9.  Final report
------------------------------------------------- */
SELECT
    a.address,

    b.balance,

    h.R_active_hour,
    h.active_days,

    ti.in_trace_count,
    ti.in_addr_count,
    ti.in_transfer_count,
    ROUND(ti.in_avg_amount,      4)  AS in_avg_amount,

    g.avg_gas_used,
    g.std_gas_used,

    to1.out_trace_count,
    to1.out_addr_count,
    to1.out_transfer_count,
    ROUND(to1.out_avg_amount,     4) AS out_avg_amount,

    tk_in.token_in_tnx,
    tk_in.token_in_type,
    tk_in.token_from_addr,

    tk_out.token_out_tnx,
    tk_out.token_out_type,
    tk_out.token_to_addr,

    rs.reward_amount,
    cs.contract_create_count,
    fs.failure_count,
    bc.bytecode_size

FROM all_addresses                      a
LEFT JOIN balance            b   ON a.address = b.address
LEFT JOIN hourly_metric       h   ON a.address = h.address
LEFT JOIN trace_in            ti  ON a.address = ti.address
LEFT JOIN trace_out           to1 ON a.address = to1.address
LEFT JOIN gas_in              g   ON a.address = g.address
LEFT JOIN token_in            tk_in  ON a.address = tk_in.address
LEFT JOIN token_out           tk_out ON a.address = tk_out.address
LEFT JOIN reward_stats        rs  ON a.address = rs.address
LEFT JOIN create_stats        cs  ON a.address = cs.address
LEFT JOIN failure_stats       fs  ON a.address = fs.address
LEFT JOIN bytecode_stats      bc  ON a.address = bc.address

-- optional ordering: richest first
ORDER BY b.balance DESC NULLS LAST, a.address;