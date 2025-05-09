/* ===============================================================
   Comprehensive address-level report – activity prior to 2017-01-01
   --------------------------------------------------------------- */
WITH
/* ---------- basic ETH balance components ---------- */
tx_in AS (        -- successful incoming transactions
    SELECT
        "to_address"  AS addr,
        SUM("value")  AS wei_in
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "block_timestamp" < 1483228800000000        -- 2017-01-01 (µs)
      AND "receipt_status" = 1
      AND "to_address"    IS NOT NULL
    GROUP BY "to_address"
),
tx_out AS (       -- successful outgoing transactions + fees
    SELECT
        "from_address"                            AS addr,
        SUM("value")                              AS wei_out,
        SUM("gas_price" * "receipt_gas_used")     AS tx_fee
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "block_timestamp" < 1483228800000000
      AND "receipt_status" = 1
      AND "from_address"  IS NOT NULL
    GROUP BY "from_address"
),
balance_eth AS (
    SELECT
        COALESCE(i.addr, o.addr)                                       AS addr,
        ( COALESCE(i.wei_in ,0)
        - COALESCE(o.wei_out,0)
        - COALESCE(o.tx_fee ,0) ) / 1e18                               AS balance
    FROM tx_in i
    FULL OUTER JOIN tx_out o ON i.addr = o.addr
),

/* ---------- trace-based general transaction statistics ---------- */
traces_base AS (
    SELECT *
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "block_timestamp" < 1483228800000000
      AND "trace_type" = 'call'
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
),
traces_in AS (
    SELECT
        "to_address"                             AS addr,
        COUNT(*)                                 AS in_trace_count,
        COUNT(DISTINCT "from_address")           AS in_addr_count,
        COUNT_IF("value" <> 0)                   AS in_transfer_count,
        AVG(CASE WHEN "value" <> 0 THEN "value" END)/1e18  AS in_avg_amount,
        AVG("gas_used")                          AS avg_gas_used,
        STDDEV_SAMP("gas_used")                  AS std_gas_used
    FROM traces_base
    WHERE "to_address" IS NOT NULL
    GROUP BY "to_address"
),
traces_out AS (
    SELECT
        "from_address"                           AS addr,
        COUNT(*)                                 AS out_trace_count,
        COUNT(DISTINCT "to_address")             AS out_addr_count,
        COUNT_IF("value" <> 0)                   AS out_transfer_count,
        AVG(CASE WHEN "value" <> 0 THEN "value" END)/1e18  AS out_avg_amount
    FROM traces_base
    WHERE "from_address" IS NOT NULL
    GROUP BY "from_address"
),

/* ---------- ERC-20 token transfers ---------- */
token_in AS (
    SELECT
        "to_address"                         AS addr,
        COUNT(*)                             AS token_in_tnx,
        COUNT(DISTINCT "token_address")      AS token_in_type,
        COUNT(DISTINCT "from_address")       AS token_from_addr
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE "block_timestamp" < 1483228800000000
      AND "to_address" IS NOT NULL
    GROUP BY "to_address"
),
token_out AS (
    SELECT
        "from_address"                       AS addr,
        COUNT(*)                             AS token_out_tnx,
        COUNT(DISTINCT "token_address")      AS token_out_type,
        COUNT(DISTINCT "to_address")         AS token_to_addr
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE "block_timestamp" < 1483228800000000
      AND "from_address" IS NOT NULL
    GROUP BY "from_address"
),

/* ---------- mining rewards ---------- */
rewards AS (
    SELECT
        "to_address"          AS addr,
        SUM("value")/1e18     AS reward_amount
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "block_timestamp" < 1483228800000000
      AND "trace_type" = 'reward'
      AND "to_address" IS NOT NULL
    GROUP BY "to_address"
),

/* ---------- contract creations & failures ---------- */
contract_creates AS (
    SELECT
        "from_address"                AS addr,
        COUNT(*)                      AS contract_create_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "block_timestamp" < 1483228800000000
      AND "receipt_contract_address" IS NOT NULL
      AND "from_address" IS NOT NULL
    GROUP BY "from_address"
),
failures AS (
    SELECT
        "from_address"        AS addr,
        COUNT(*)              AS failure_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "block_timestamp" < 1483228800000000
      AND "receipt_status" = 0
      AND "from_address"  IS NOT NULL
    GROUP BY "from_address"
),

/* ---------- contract byte-code size ---------- */
bytecode AS (
    SELECT
        "address"          AS addr,
        LENGTH("bytecode") AS bytecode_size
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.CONTRACTS
    WHERE "block_timestamp" < 1483228800000000
),

/* ---------- universal activity set (tx + traces) ---------- */
all_activity AS (
    SELECT "from_address" AS addr, "block_timestamp" AS ts
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE  "block_timestamp" < 1483228800000000 AND "from_address" IS NOT NULL
    UNION ALL
    SELECT "to_address"   AS addr, "block_timestamp" AS ts
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE  "block_timestamp" < 1483228800000000 AND "to_address" IS NOT NULL
    UNION ALL
    SELECT "from_address" AS addr, "block_timestamp" AS ts
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "block_timestamp" < 1483228800000000 AND "from_address" IS NOT NULL
    UNION ALL
    SELECT "to_address"   AS addr, "block_timestamp" AS ts
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "block_timestamp" < 1483228800000000 AND "to_address" IS NOT NULL
),

/* ---------- active days per address ---------- */
active_days AS (
    SELECT
        addr,
        COUNT(DISTINCT TO_DATE(TO_TIMESTAMP(ts/1000000))) AS active_days
    FROM all_activity
    GROUP BY addr
),

/* ---------- hourly activity uniformity (R) ---------- */
hour_vector AS (
    SELECT
        addr,
        COUNT(*)                                              AS n_total,
        SUM(COS(2*PI()*EXTRACT(hour FROM TO_TIMESTAMP(ts/1000000))/24)) AS sum_cos,
        SUM(SIN(2*PI()*EXTRACT(hour FROM TO_TIMESTAMP(ts/1000000))/24)) AS sum_sin
    FROM all_activity
    GROUP BY addr
),
hour_consistency AS (
    SELECT
        addr,
        SQRT( POWER(sum_cos,2) + POWER(sum_sin,2) ) / n_total AS R_active_hour
    FROM hour_vector
    WHERE n_total > 24
),

/* ---------- master address list ---------- */
base_addresses AS (
    SELECT DISTINCT addr FROM (
        SELECT addr FROM balance_eth
        UNION SELECT addr FROM traces_in
        UNION SELECT addr FROM traces_out
        UNION SELECT addr FROM token_in
        UNION SELECT addr FROM token_out
        UNION SELECT addr FROM rewards
        UNION SELECT addr FROM contract_creates
        UNION SELECT addr FROM failures
        UNION SELECT addr FROM bytecode
    )
)

/* ---------- final assembled report ---------- */
SELECT
    b.addr                                    AS "address",
    be.balance                                AS "balance",
    hc.R_active_hour                          AS "R_active_hour",
    ad.active_days                            AS "active_days",

    ti.in_trace_count                         AS "in_trace_count",
    ti.in_addr_count                          AS "in_addr_count",
    ti.in_transfer_count                      AS "in_transfer_count",
    ti.in_avg_amount                          AS "in_avg_amount",
    ti.avg_gas_used                           AS "avg_gas_used",
    ti.std_gas_used                           AS "std_gas_used",

    to1.out_trace_count                       AS "out_trace_count",
    to1.out_addr_count                        AS "out_addr_count",
    to1.out_transfer_count                    AS "out_transfer_count",
    to1.out_avg_amount                        AS "out_avg_amount",

    tk_i.token_in_tnx                         AS "token_in_tnx",
    tk_i.token_in_type                        AS "token_in_type",
    tk_i.token_from_addr                      AS "token_from_addr",

    tk_o.token_out_tnx                        AS "token_out_tnx",
    tk_o.token_out_type                       AS "token_out_type",
    tk_o.token_to_addr                        AS "token_to_addr",

    rw.reward_amount                          AS "reward_amount",
    cc.contract_create_count                  AS "contract_create_count",
    fl.failure_count                          AS "failure_count",
    bc.bytecode_size                          AS "bytecode_size"
FROM base_addresses      b
LEFT JOIN balance_eth      be   ON b.addr = be.addr
LEFT JOIN hour_consistency hc   ON b.addr = hc.addr
LEFT JOIN active_days      ad   ON b.addr = ad.addr
LEFT JOIN traces_in        ti   ON b.addr = ti.addr
LEFT JOIN traces_out       to1  ON b.addr = to1.addr
LEFT JOIN token_in         tk_i ON b.addr = tk_i.addr
LEFT JOIN token_out        tk_o ON b.addr = tk_o.addr
LEFT JOIN rewards          rw   ON b.addr = rw.addr
LEFT JOIN contract_creates cc   ON b.addr = cc.addr
LEFT JOIN failures         fl   ON b.addr = fl.addr
LEFT JOIN bytecode         bc   ON b.addr = bc.addr
ORDER BY be.balance DESC NULLS LAST;