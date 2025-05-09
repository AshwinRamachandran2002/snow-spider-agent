WITH
/*--------------------------------------------------------------------*
 | 1. constant for the time‑limit (01‑Jan‑2017)                        |
 *--------------------------------------------------------------------*/
cutoff_ts AS (
    SELECT 1483228800000000 AS ts        -- micro‑seconds
),
/*--------------------------------------------------------------------*
 | 2. traces to be analysed (successful & harmless call‑types only)    |
 *--------------------------------------------------------------------*/
base_traces AS (
    SELECT *
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES" t
    JOIN cutoff_ts c
      ON t."block_timestamp" < c.ts
    WHERE t."status" = 1
      AND ( t."call_type" IS NULL
            OR UPPER(t."call_type") NOT IN ('DELEGATECALL','CALLCODE','STATICCALL') )
),
/*--------------------------------------------------------------------*
 | 3. incoming / outgoing trace statistics                            |
 *--------------------------------------------------------------------*/
trace_in AS (
    SELECT
        t."to_address"                   AS address,
        COUNT(*)                         AS in_trace_count,
        COUNT(DISTINCT t."from_address") AS in_addr_count,
        COUNT_IF(t."value" > 0)          AS in_transfer_count,
        AVG(t."value"/1e18)              AS in_avg_amount,
        STDDEV_SAMP(t."value"/1e18)      AS in_std_amount,
        AVG(t."gas_used")                AS avg_gas_used,
        STDDEV_SAMP(t."gas_used")        AS std_gas_used
    FROM base_traces t
    GROUP BY address
),
trace_out AS (
    SELECT
        t."from_address"                 AS address,
        COUNT(*)                         AS out_trace_count,
        COUNT(DISTINCT t."to_address")   AS out_addr_count,
        COUNT_IF(t."value" > 0)          AS out_transfer_count,
        AVG(t."value"/1e18)              AS out_avg_amount,
        STDDEV_SAMP(t."value"/1e18)      AS out_std_amount
    FROM base_traces t
    GROUP BY address
),
/*--------------------------------------------------------------------*
 | 4. ETH balance components                                          |
 *--------------------------------------------------------------------*/
total_received AS (
    SELECT "to_address"   AS address,
           SUM("value")   AS total_received_value
    FROM base_traces
    GROUP BY address
),
total_sent AS (
    SELECT "from_address" AS address,
           SUM("value")   AS total_sent_value
    FROM base_traces
    GROUP BY address
),
tx_fees AS (
    SELECT tr."from_address"                              AS address,
           SUM(tr."receipt_gas_used"*tr."gas_price")      AS total_fee
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS" tr
    JOIN cutoff_ts c
      ON tr."block_timestamp" < c.ts
    WHERE tr."receipt_status" = 1
    GROUP BY address
),
balance_calc AS (
    SELECT
        COALESCE(r.address , s.address , f.address)                          AS address,
        COALESCE(r.total_received_value,0)
      - COALESCE(s.total_sent_value   ,0)
      - COALESCE(f.total_fee          ,0)                                    AS balance_wei
    FROM total_received r
         FULL OUTER JOIN total_sent s ON r.address = s.address
         FULL OUTER JOIN tx_fees   f ON COALESCE(r.address,s.address)=f.address
),
/*--------------------------------------------------------------------*
 | 5. ERC‑20 token statistics                                         |
 *--------------------------------------------------------------------*/
token_in AS (
    SELECT
        tt."to_address"                      AS address,
        COUNT(*)                             AS token_in_tnx,
        COUNT(DISTINCT tt."token_address")   AS token_in_type,
        COUNT(DISTINCT tt."from_address")    AS token_from_addr
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
    JOIN cutoff_ts c
      ON tt."block_timestamp" < c.ts
    GROUP BY address
),
token_out AS (
    SELECT
        tt."from_address"                    AS address,
        COUNT(*)                             AS token_out_tnx,
        COUNT(DISTINCT tt."token_address")   AS token_out_type,
        COUNT(DISTINCT tt."to_address")      AS token_to_addr
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
    JOIN cutoff_ts c
      ON tt."block_timestamp" < c.ts
    GROUP BY address
),
/*--------------------------------------------------------------------*
 | 6. mining rewards & contract creation                              |
 *--------------------------------------------------------------------*/
rewards AS (
    SELECT "to_address"                      AS address,
           SUM("value")/1e18                 AS reward_amount
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES" t
    JOIN cutoff_ts c
      ON t."block_timestamp" < c.ts
    WHERE t."trace_type" = 'reward'
    GROUP BY address
),
contract_creates AS (
    SELECT "from_address" AS address,
           COUNT(*)       AS contract_create_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES" t
    JOIN cutoff_ts c
      ON t."block_timestamp" < c.ts
    WHERE t."trace_type" = 'create'
    GROUP BY address
),
/*--------------------------------------------------------------------*
 | 7. failures and byte‑code size                                     |
 *--------------------------------------------------------------------*/
failure_tx AS (
    SELECT tr."from_address" AS address,
           COUNT(*)          AS failure_count
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS" tr
    JOIN cutoff_ts c
      ON tr."block_timestamp" < c.ts
    WHERE tr."receipt_status" = 0
    GROUP BY address
),
bytecode AS (
    SELECT c."address"                               AS address,
           AVG( (LENGTH(c."bytecode")-2)/2 )         AS bytecode_size   -- bytes
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."CONTRACTS" c
    JOIN cutoff_ts cut
      ON c."block_timestamp" < cut.ts
    WHERE c."bytecode" IS NOT NULL
    GROUP BY address
),
/*--------------------------------------------------------------------*
 | 8. hourly activity & active days                                   |
 *--------------------------------------------------------------------*/
activity_raw AS (
    SELECT
        addr,
        ts,
        MOD(FLOOR(ts/1000000/3600),24)              AS h,
        FLOOR(ts/1000000/86400)                     AS day_id
    FROM (
          SELECT "from_address" AS addr, "block_timestamp" AS ts
          FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES"       t JOIN cutoff_ts c ON t."block_timestamp"<c.ts
          UNION ALL
          SELECT "to_address"   AS addr, "block_timestamp" AS ts
          FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES"       t JOIN cutoff_ts c ON t."block_timestamp"<c.ts
          UNION ALL
          SELECT "from_address" AS addr, "block_timestamp" AS ts
          FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS" x JOIN cutoff_ts c ON x."block_timestamp"<c.ts
          UNION ALL
          SELECT "to_address"   AS addr, "block_timestamp" AS ts
          FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS" x JOIN cutoff_ts c ON x."block_timestamp"<c.ts
    )
    WHERE addr IS NOT NULL
),
activity AS (
    SELECT
        addr                                        AS address,
        COUNT(*)                                    AS tx_count,
        SUM(COS(2*PI()*h/24))                       AS sum_c,
        SUM(SIN(2*PI()*h/24))                       AS sum_s,
        COUNT(DISTINCT day_id)                      AS active_days
    FROM activity_raw
    GROUP BY addr
    HAVING tx_count > 24
),
activity_metrics AS (
    SELECT
        address,
        SQRT(sum_c*sum_c + sum_s*sum_s)/tx_count    AS R_active_hour,
        active_days
    FROM activity
),
/*--------------------------------------------------------------------*
 | 9. list of all addresses active before 2017‑01‑01                   |
 *--------------------------------------------------------------------*/
all_addresses AS (
    SELECT DISTINCT address
    FROM (
          SELECT "from_address" AS address, "block_timestamp" FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS"
          UNION
          SELECT "to_address"   AS address, "block_timestamp" FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS"
          UNION
          SELECT "from_address" AS address, "block_timestamp" FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES"
          UNION
          SELECT "to_address"   AS address, "block_timestamp" FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES"
          UNION
          SELECT "from_address" AS address, "block_timestamp" FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS"
          UNION
          SELECT "to_address"   AS address, "block_timestamp" FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS"
    ) z
    JOIN cutoff_ts c
      ON z."block_timestamp" < c.ts
    WHERE address IS NOT NULL
)
/*--------------------------------------------------------------------*
 | 10. final report                                                   |
 *--------------------------------------------------------------------*/
SELECT
    a.address,

    ROUND(b.balance_wei/1e18, 8)                 AS balance,

    act.R_active_hour,
    act.active_days,

    ti.in_trace_count,
    ti.in_addr_count,
    ti.in_transfer_count,
    ROUND(ti.in_avg_amount ,4)                   AS in_avg_amount,
    ti.avg_gas_used                              AS avg_gas_used,
    ti.std_gas_used                              AS std_gas_used,

    tr_out.out_trace_count,
    tr_out.out_addr_count,
    tr_out.out_transfer_count,
    ROUND(tr_out.out_avg_amount,4)               AS out_avg_amount,

    tin.token_in_tnx,
    tin.token_in_type,
    tin.token_from_addr,

    tout.token_out_tnx,
    tout.token_out_type,
    tout.token_to_addr,

    rew.reward_amount,
    cc.contract_create_count,
    fail.failure_count,
    bc.bytecode_size

FROM all_addresses           a
LEFT JOIN balance_calc       b       ON a.address = b.address
LEFT JOIN activity_metrics   act     ON a.address = act.address
LEFT JOIN trace_in           ti      ON a.address = ti.address
LEFT JOIN trace_out          tr_out  ON a.address = tr_out.address
LEFT JOIN token_in           tin     ON a.address = tin.address
LEFT JOIN token_out          tout    ON a.address = tout.address
LEFT JOIN rewards            rew     ON a.address = rew.address
LEFT JOIN contract_creates   cc      ON a.address = cc.address
LEFT JOIN failure_tx         fail    ON a.address = fail.address
LEFT JOIN bytecode           bc      ON a.address = bc.address
/* omit rows with absolutely no statistics */
WHERE COALESCE(b.balance_wei,
               ti.in_trace_count,
               tr_out.out_trace_count,
               tin.token_in_tnx,
               tout.token_out_tnx,
               rew.reward_amount,
               cc.contract_create_count,
               fail.failure_count,
               bc.bytecode_size) IS NOT NULL;