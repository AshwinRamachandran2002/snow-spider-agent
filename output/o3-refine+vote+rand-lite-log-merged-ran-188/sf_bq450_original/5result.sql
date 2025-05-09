/* ============================================================
   Comprehensive Ethereum‑address report (activity before 2017‑01‑01)
   ------------------------------------------------------------
   • All time units in the raw data are micro‑seconds;
     2017‑01‑01 00:00:00 UTC  = 1483228800 s = 1 483 228 800 000 000 µs
   • ETH‑denominated amounts are scaled to Ether ( ÷ 1e18 )
   • “call” traces exclude delegatecall/callcode/staticcall
   ============================================================ */

WITH
/* ----------------------------------------------------------------
   1. Constant cut‑off (01‑Jan‑2017)
----------------------------------------------------------------- */
params AS (
    SELECT 1483228800000000::NUMBER AS cutoff
),

/* ----------------------------------------------------------------
   2. Successful external transactions before cut‑off
----------------------------------------------------------------- */
txn AS (
    SELECT
        "block_timestamp",
        "from_address",
        "to_address",
        "value",
        "gas_price",
        "receipt_gas_used",
        ("gas_price" * "receipt_gas_used")                      AS fee
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS", params
    WHERE "block_timestamp" < cutoff
      AND "receipt_status" = 1
),

/* ----------------------------------------------------------------
   3‑a. Incoming‑transaction statistics
----------------------------------------------------------------- */
addr_txn_in AS (
    SELECT
        "to_address"                                           AS address,
        COUNT(*)                                               AS in_trace_count,
        COUNT(DISTINCT "from_address")                         AS in_addr_count,
        COUNT_IF("value" > 0)                                  AS in_transfer_count,
        AVG("value")/1e18                                      AS in_avg_amount
    FROM txn
    GROUP BY address
),

/* ----------------------------------------------------------------
   3‑b. Outgoing‑transaction statistics (+ accumulated fees)
----------------------------------------------------------------- */
addr_txn_out AS (
    SELECT
        "from_address"                                         AS address,
        COUNT(*)                                               AS out_trace_count,
        COUNT(DISTINCT "to_address")                           AS out_addr_count,
        COUNT_IF("value" > 0)                                  AS out_transfer_count,
        AVG("value")/1e18                                      AS out_avg_amount,
        SUM(fee)                                               AS total_fee,
        SUM("value")                                           AS sent_value
    FROM txn
    GROUP BY address
),

/* ----------------------------------------------------------------
   4. Received value
----------------------------------------------------------------- */
addr_txn_recv AS (
    SELECT
        "to_address"                                           AS address,
        SUM("value")                                           AS recv_value
    FROM txn
    GROUP BY address
),

/* ----------------------------------------------------------------
   5. Net balance (Ether)
----------------------------------------------------------------- */
balance_calc AS (
    SELECT
        COALESCE(r.address, s.address)                         AS address,
        (COALESCE(r.recv_value ,0) -
         COALESCE(s.sent_value,0) -
         COALESCE(s.total_fee ,0) ) / 1e18                     AS balance
    FROM addr_txn_recv r
    FULL OUTER JOIN addr_txn_out  s  ON r.address = s.address
),

/* ----------------------------------------------------------------
   6. Hourly‑activity consistency & active‑day count
----------------------------------------------------------------- */
hourly_activity AS (
    SELECT
        address,
        COUNT(*)                                               AS txn_count,
        COUNT(DISTINCT DATE_TRUNC('day',
               TO_TIMESTAMP_NTZ("block_timestamp"/1000000)))   AS active_days,
        /*   R = √[(Σcosθ / n)² + (Σsinθ / n)²]   */
        SQRT(  POWER(AVG(COS(2*PI()*hr/24)),2)
             + POWER(AVG(SIN(2*PI()*hr/24)),2) )               AS R_active_hour
    FROM (
        SELECT  "from_address"       AS address,
                "block_timestamp",
                EXTRACT(hour FROM
                        TO_TIMESTAMP_NTZ("block_timestamp"/1000000)) AS hr
        FROM txn
        UNION ALL
        SELECT  "to_address"         AS address,
                "block_timestamp",
                EXTRACT(hour FROM
                        TO_TIMESTAMP_NTZ("block_timestamp"/1000000)) AS hr
        FROM txn
    )
    GROUP BY address
    HAVING COUNT(*) > 24                /* only if >24 activities */
),

/* ----------------------------------------------------------------
   7. Relevant successful “call” traces (excluding delegatecall …)
----------------------------------------------------------------- */
traces_pre AS (
    SELECT *
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", params
    WHERE "block_timestamp" < cutoff
      AND "trace_type"   = 'call'
      AND ("call_type" IS NULL OR "call_type" NOT IN ('delegatecall','callcode','staticcall'))
      AND "status"       = 1
),

/* ----------------------------------------------------------------
   8. Gas statistics for incoming calls
----------------------------------------------------------------- */
trace_in AS (
    SELECT
        "to_address"                                         AS address,
        AVG("gas_used")                                      AS avg_gas_used,
        STDDEV_SAMP("gas_used")                              AS std_gas_used
    FROM traces_pre
    WHERE "to_address" IS NOT NULL
    GROUP BY "to_address"
),

/* ----------------------------------------------------------------
   9. ERC‑20 token transfers before cut‑off
----------------------------------------------------------------- */
token_pre AS (
    SELECT *
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS", params
    WHERE "block_timestamp" < cutoff
),

token_in AS (
    SELECT
        "to_address"                                         AS address,
        COUNT(*)                                             AS token_in_tnx,
        COUNT(DISTINCT "token_address")                      AS token_in_type,
        COUNT(DISTINCT "from_address")                       AS token_from_addr
    FROM token_pre
    GROUP BY address
),

token_out AS (
    SELECT
        "from_address"                                       AS address,
        COUNT(*)                                             AS token_out_tnx,
        COUNT(DISTINCT "token_address")                      AS token_out_type,
        COUNT(DISTINCT "to_address")                         AS token_to_addr
    FROM token_pre
    GROUP BY address
),

/* ----------------------------------------------------------------
   10. Mining rewards
----------------------------------------------------------------- */
rewards AS (
    SELECT
        "to_address"                                         AS address,
        SUM("value")/1e18                                    AS reward_amount
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", params
    WHERE "block_timestamp" < cutoff
      AND "trace_type" = 'reward'
    GROUP BY "to_address"
),

/* ----------------------------------------------------------------
   11. Contract creations
----------------------------------------------------------------- */
contract_creations AS (
    SELECT
        "from_address"                                       AS address,
        COUNT(*)                                             AS contract_create_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", params
    WHERE "block_timestamp" < cutoff
      AND "trace_type" = 'create'
    GROUP BY "from_address"
),

/* ----------------------------------------------------------------
   12. Failed traces
----------------------------------------------------------------- */
failures AS (
    SELECT
        "from_address"                                       AS address,
        COUNT(*)                                             AS failure_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES", params
    WHERE "block_timestamp" < cutoff
      AND "status" = 0
    GROUP BY "from_address"
),

/* ----------------------------------------------------------------
   13. Byte‑code length of contracts created (max per creator)
----------------------------------------------------------------- */
bytecode AS (
    SELECT
        c."address"                                          AS contract_addr,
        (LENGTH(c."bytecode") - 2)/2                         AS bytecode_size /* hex → bytes */
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."CONTRACTS" c, params
    WHERE c."block_timestamp" < cutoff
),

creator_map AS (   /* map contract → creator */
    SELECT
        t."from_address"                                     AS address,
        t."to_address"                                       AS contract_addr
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES" t, params
    WHERE t."block_timestamp" < cutoff
      AND t."trace_type" = 'create'
),

bytecode_by_creator AS (
    SELECT
        m.address,
        MAX(b.bytecode_size)                                 AS bytecode_size
    FROM creator_map m
    JOIN bytecode   b  ON b.contract_addr = m.contract_addr
    GROUP BY m.address
),

/* ----------------------------------------------------------------
   14. Master list of addresses having any pre‑2017 activity
----------------------------------------------------------------- */
all_addresses AS (
      SELECT DISTINCT address FROM balance_calc
 UNION SELECT DISTINCT address FROM hourly_activity
 UNION SELECT DISTINCT address FROM addr_txn_in
 UNION SELECT DISTINCT address FROM addr_txn_out
 UNION SELECT DISTINCT address FROM token_in
 UNION SELECT DISTINCT address FROM token_out
 UNION SELECT DISTINCT address FROM rewards
 UNION SELECT DISTINCT address FROM contract_creations
 UNION SELECT DISTINCT address FROM failures
)

/* ----------------------------------------------------------------
   15. Final consolidated report
----------------------------------------------------------------- */
SELECT
      a.address
    , COALESCE(b.balance                 , 0)                AS balance
    , h.R_active_hour
    , h.active_days
    , COALESCE(i.in_trace_count          , 0)                AS in_trace_count
    , COALESCE(i.in_addr_count           , 0)                AS in_addr_count
    , COALESCE(i.in_transfer_count       , 0)                AS in_transfer_count
    , COALESCE(i.in_avg_amount           , 0)                AS in_avg_amount
    , COALESCE(ti.avg_gas_used           , 0)                AS avg_gas_used
    , COALESCE(ti.std_gas_used           , 0)                AS std_gas_used
    , COALESCE(o.out_trace_count         , 0)                AS out_trace_count
    , COALESCE(o.out_addr_count          , 0)                AS out_addr_count
    , COALESCE(o.out_transfer_count      , 0)                AS out_transfer_count
    , COALESCE(o.out_avg_amount          , 0)                AS out_avg_amount
    , COALESCE(kin.token_in_tnx          , 0)                AS token_in_tnx
    , COALESCE(kin.token_in_type         , 0)                AS token_in_type
    , COALESCE(kin.token_from_addr       , 0)                AS token_from_addr
    , COALESCE(kout.token_out_tnx        , 0)                AS token_out_tnx
    , COALESCE(kout.token_out_type       , 0)                AS token_out_type
    , COALESCE(kout.token_to_addr        , 0)                AS token_to_addr
    , COALESCE(r.reward_amount           , 0)                AS reward_amount
    , COALESCE(cc.contract_create_count  , 0)                AS contract_create_count
    , COALESCE(f.failure_count           , 0)                AS failure_count
    , COALESCE(bc.bytecode_size          , 0)                AS bytecode_size
FROM           all_addresses      a
LEFT JOIN      balance_calc       b   ON a.address = b.address
LEFT JOIN      hourly_activity    h   ON a.address = h.address
LEFT JOIN      addr_txn_in        i   ON a.address = i.address
LEFT JOIN      addr_txn_out       o   ON a.address = o.address
LEFT JOIN      trace_in           ti  ON a.address = ti.address
LEFT JOIN      token_in           kin ON a.address = kin.address
LEFT JOIN      token_out          kout ON a.address = kout.address
LEFT JOIN      rewards            r   ON a.address = r.address
LEFT JOIN      contract_creations cc  ON a.address = cc.address
LEFT JOIN      failures           f   ON a.address = f.address
LEFT JOIN      bytecode_by_creator bc ON a.address = bc.address
ORDER BY balance DESC NULLS LAST, a.address;