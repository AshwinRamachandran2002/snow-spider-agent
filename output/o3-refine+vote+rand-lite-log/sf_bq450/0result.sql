/* ---------------------------------------------------------------
   Corrected comprehensive per‑address report (Snowflake dialect)
-----------------------------------------------------------------*/
WITH

/* cut‑off moment (micro‑seconds since epoch for 2017‑01‑01 UTC) */
threshold AS (SELECT 1483228800000000 AS ts),

/* 1. all addresses active before the cut‑off ------------------- */
addresses AS (
      SELECT DISTINCT "from_address" AS address
        FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS , threshold
       WHERE "block_timestamp" < ts  AND "from_address" IS NOT NULL
 UNION
      SELECT DISTINCT "to_address"   AS address
        FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS , threshold
       WHERE "block_timestamp" < ts  AND "to_address"   IS NOT NULL
 UNION
      SELECT DISTINCT "from_address" AS address
        FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES , threshold
       WHERE "block_timestamp" < ts  AND "from_address" IS NOT NULL
 UNION
      SELECT DISTINCT "to_address"   AS address
        FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES , threshold
       WHERE "block_timestamp" < ts  AND "to_address"   IS NOT NULL
 UNION
      SELECT DISTINCT "from_address" AS address
        FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS , threshold
       WHERE "block_timestamp" < ts  AND "from_address" IS NOT NULL
 UNION
      SELECT DISTINCT "to_address"   AS address
        FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS , threshold
       WHERE "block_timestamp" < ts  AND "to_address"   IS NOT NULL
 UNION
      SELECT DISTINCT "address"      AS address
        FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.CONTRACTS , threshold
       WHERE "block_timestamp" < ts
),

/* 2. activity over time ---------------------------------------- */
activity AS (
   SELECT
          a.address,
          COUNT(*)                                                         AS total_activity,
          COUNT(DISTINCT DATE_TRUNC('day',
                     TO_TIMESTAMP_NTZ(t."block_timestamp"/1000000)))       AS active_days,
          SUM(COS(2*PI()*EXTRACT(hour FROM
                     TO_TIMESTAMP_NTZ(t."block_timestamp"/1000000))/24))   AS sum_cos,
          SUM(SIN(2*PI()*EXTRACT(hour FROM
                     TO_TIMESTAMP_NTZ(t."block_timestamp"/1000000))/24))   AS sum_sin
     FROM addresses a
     JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t
       ON t."block_timestamp" < 1483228800000000
      AND (t."from_address" = a.address OR t."to_address" = a.address)
   GROUP BY a.address
),

/* 3. ETH balance elements -------------------------------------- */
balance AS (
   SELECT
        a.address,
        SUM(CASE WHEN t."to_address"   = a.address THEN t."value" ELSE 0 END)               AS total_in,
        SUM(CASE WHEN t."from_address" = a.address THEN t."value" ELSE 0 END)               AS total_out,
        SUM(CASE WHEN t."from_address" = a.address
                 THEN t."gas_price" * t."receipt_gas_used" ELSE 0 END)                      AS total_fee
     FROM addresses a
     JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t
       ON t."block_timestamp" < 1483228800000000
      AND t."receipt_status" = 1
      AND (t."from_address" = a.address OR t."to_address" = a.address)
   GROUP BY a.address
),

/* 4. incoming / outgoing TX statistics ------------------------- */
in_out_txn AS (
   SELECT
        a.address,
        SUM(CASE WHEN t."to_address"   = a.address THEN 1 ELSE 0 END)                      AS in_trace_count,
        COUNT(DISTINCT CASE WHEN t."to_address"   = a.address THEN t."from_address" END)   AS in_addr_count,
        SUM(CASE WHEN t."to_address"   = a.address AND t."value" > 0 THEN 1 END)           AS in_transfer_count,
        (  SUM(CASE WHEN t."to_address"   = a.address AND t."value" > 0 THEN t."value" END)
         / NULLIF(SUM(CASE WHEN t."to_address"   = a.address AND t."value" > 0 THEN 1 END),0)
        )/1e18                                                                             AS in_avg_amount,
        SUM(CASE WHEN t."from_address" = a.address THEN 1 ELSE 0 END)                      AS out_trace_count,
        COUNT(DISTINCT CASE WHEN t."from_address" = a.address THEN t."to_address" END)     AS out_addr_count,
        SUM(CASE WHEN t."from_address" = a.address AND t."value" > 0 THEN 1 END)           AS out_transfer_count,
        (  SUM(CASE WHEN t."from_address" = a.address AND t."value" > 0 THEN t."value" END)
         / NULLIF(SUM(CASE WHEN t."from_address" = a.address AND t."value" > 0 THEN 1 END),0)
        )/1e18                                                                             AS out_avg_amount
     FROM addresses a
     JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t
       ON t."block_timestamp" < 1483228800000000
      AND (t."from_address" = a.address OR t."to_address" = a.address)
   GROUP BY a.address
),

/* 5. gas statistics for incoming plain CALL traces -------------- */
gas_stats AS (
   SELECT
        t."to_address"                                            AS address,
        AVG(t."gas_used")                                         AS avg_gas_used,
        STDDEV_SAMP(t."gas_used")                                 AS std_gas_used
     FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES t
    WHERE t."block_timestamp" < 1483228800000000
      AND t."trace_type" = 'call'
      AND (t."call_type" IS NULL OR t."call_type" NOT IN ('delegatecall','callcode','staticcall'))
      AND t."to_address" IS NOT NULL
      AND t."gas_used" IS NOT NULL
   GROUP BY t."to_address"
),

/* 6. ERC‑token traffic ----------------------------------------- */
token_metrics AS (
   SELECT
        a.address,
        COUNT(CASE WHEN tt."to_address"   = a.address THEN 1 END)                         AS token_in_tnx,
        COUNT(CASE WHEN tt."from_address" = a.address THEN 1 END)                         AS token_out_tnx,
        COUNT(DISTINCT CASE WHEN tt."to_address"   = a.address THEN tt."token_address" END)  AS token_in_type,
        COUNT(DISTINCT CASE WHEN tt."from_address" = a.address THEN tt."token_address" END)  AS token_out_type,
        COUNT(DISTINCT CASE WHEN tt."to_address"   = a.address THEN tt."from_address"  END)  AS token_from_addr,
        COUNT(DISTINCT CASE WHEN tt."from_address" = a.address THEN tt."to_address"    END)  AS token_to_addr
     FROM addresses a
LEFT JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS tt
       ON tt."block_timestamp" < 1483228800000000
      AND (tt."from_address" = a.address OR tt."to_address" = a.address)
   GROUP BY a.address
),

/* 7. mining rewards -------------------------------------------- */
rewards AS (
   SELECT
        t."to_address"                                    AS address,
        SUM(t."value")/1e18                               AS reward_amount
     FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES t
    WHERE t."block_timestamp" < 1483228800000000
      AND t."trace_type" = 'reward'
      AND t."to_address" IS NOT NULL
   GROUP BY t."to_address"
),

/* 8. contract creations ---------------------------------------- */
contract_create AS (
   SELECT
        "from_address"                                    AS address,
        COUNT(*)                                          AS contract_create_count
     FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "block_timestamp" < 1483228800000000
      AND "receipt_contract_address" IS NOT NULL
   GROUP BY "from_address"
),

/* 9. failed transactions --------------------------------------- */
failures AS (
   SELECT
        "from_address"                                    AS address,
        COUNT(*)                                          AS failure_count
     FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "block_timestamp" < 1483228800000000
      AND "receipt_status" = 0
   GROUP BY "from_address"
),

/* 10. byte‑code size for contracts ----------------------------- */
bytecode AS (
   SELECT
        "address" AS address,
        (LENGTH("bytecode")-2)/2                          AS bytecode_size
     FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.CONTRACTS
    WHERE "block_timestamp" < 1483228800000000
)

/* ========================= FINAL REPORT ======================= */
SELECT
       a.address,

       /* ETH balance (Wei → Ether) */
       ( COALESCE(b.total_in ,0)
       - COALESCE(b.total_out,0)
       - COALESCE(b.total_fee,0) ) / 1e18                                  AS balance,

       /* Hourly activity uniformity */
       CASE WHEN act.total_activity > 24
            THEN SQRT( POWER(act.sum_cos,2) + POWER(act.sum_sin,2) )
                 / act.total_activity
            ELSE NULL END                                                  AS R_active_hour,

       act.active_days,

       /* incoming tx metrics */
       io.in_trace_count,
       io.in_addr_count,
       io.in_transfer_count,
       io.in_avg_amount,
       gs.avg_gas_used,
       gs.std_gas_used,

       /* outgoing tx metrics */
       io.out_trace_count,
       io.out_addr_count,
       io.out_transfer_count,
       io.out_avg_amount,

       /* token traffic */
       tok.token_in_tnx,
       tok.token_in_type,
       tok.token_from_addr,
       tok.token_out_tnx,
       tok.token_out_type,
       tok.token_to_addr,

       /* mining & contracts */
       rew.reward_amount,
       cc.contract_create_count,

       /* failures & bytecode */
       f.failure_count,
       bc.bytecode_size

  FROM addresses                   a
  LEFT JOIN balance          b  ON a.address = b.address
  LEFT JOIN activity         act ON a.address = act.address
  LEFT JOIN in_out_txn       io  ON a.address = io.address
  LEFT JOIN gas_stats        gs  ON a.address = gs.address
  LEFT JOIN token_metrics    tok ON a.address = tok.address
  LEFT JOIN rewards          rew ON a.address = rew.address
  LEFT JOIN contract_create  cc  ON a.address = cc.address
  LEFT JOIN failures         f   ON a.address = f.address
  LEFT JOIN bytecode         bc  ON a.address = bc.address;