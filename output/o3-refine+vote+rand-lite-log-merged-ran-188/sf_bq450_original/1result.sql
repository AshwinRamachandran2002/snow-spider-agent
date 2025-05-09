WITH
/* ------------------------------------------------------- */
/* 1. constant                                             */
const AS (
    SELECT 1483228800000000::NUMBER AS "ts_limit"            -- 1 Jan 2017 (micro‑seconds)
),
/* ------------------------------------------------------- */
/* 2. traces (successful, before 2017, no *callcode* etc.) */
traces17 AS (                                              
    SELECT  t."from_address",
            t."to_address",
            t."value",
            t."gas_used",
            t."trace_type",
            t."call_type",
            t."block_timestamp"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES" t ,
            const
    WHERE   t."block_timestamp" <  "ts_limit"
      AND   t."status" = 1
      AND ( t."call_type" IS NULL 
            OR t."call_type" NOT IN ('delegatecall','callcode','staticcall') )
),
/* ------------------------------------------------------- */
/* 3. activity ‑ every trace (in + out) counts as activity */
activity_events AS (
    SELECT "from_address" AS "address", "block_timestamp" FROM traces17
    UNION ALL
    SELECT "to_address"   AS "address", "block_timestamp" FROM traces17
),
activity_stats AS (
    SELECT  a."address",
            COUNT(*)                                                    AS "activity_cnt",
            COUNT(DISTINCT DATE_TRUNC('day', TO_TIMESTAMP(a."block_timestamp"/1e6))) AS "active_days",
            /* Hourly uniformity (R)                                     */
            SQRT(
                 POW( SUM( COS( 2*PI()*EXTRACT(hour FROM TO_TIMESTAMP(a."block_timestamp"/1e6))/24) )/COUNT(*), 2 ) +
                 POW( SUM( SIN( 2*PI()*EXTRACT(hour FROM TO_TIMESTAMP(a."block_timestamp"/1e6))/24) )/COUNT(*), 2 )
            )                                                           AS "R_active_hour"
    FROM    activity_events a
    GROUP BY a."address"
    HAVING  COUNT(*) > 24               -- only addresses with >24 activities
),
/* ------------------------------------------------------- */
/* 4. gas statistics on incoming CALL traces               */
in_call_gas AS (
    SELECT  t."to_address"                                 AS "address",
            AVG(t."gas_used")                              AS "avg_gas_used",
            STDDEV_SAMP(t."gas_used")                      AS "std_gas_used"
    FROM    traces17  t
    WHERE   t."trace_type" = 'call'
    GROUP BY t."to_address"
),
/* ------------------------------------------------------- */
/* 5. transactions (root level)                            */
tx17 AS (
    SELECT  x."hash",
            x."from_address",
            x."to_address",
            x."value",
            x."gas_price",
            x."receipt_gas_used",
            x."receipt_status",
            x."receipt_contract_address",
            x."block_timestamp"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS" x , const
    WHERE   x."block_timestamp" < "ts_limit"
),
tx_ok   AS ( SELECT * FROM tx17 WHERE "receipt_status" = 1 ),
tx_fail AS ( SELECT * FROM tx17 WHERE "receipt_status" = 0 ),
/* ---------- incoming ETH --------------------------------*/
in_tx AS (
    SELECT  "to_address"                                  AS "address",
            COUNT(*)                                      AS "in_trace_count",
            COUNT(DISTINCT "from_address")                AS "in_addr_count",
            SUM( CASE WHEN "value" <> 0 THEN 1 ELSE 0 END)           AS "in_transfer_count",
            AVG("value")/1e18                             AS "in_avg_amount",
            SUM("value")                                  AS "in_value_sum"
    FROM    tx_ok
    GROUP BY "to_address"
),
/* ---------- outgoing ETH --------------------------------*/
out_tx AS (
    SELECT  "from_address"                                AS "address",
            COUNT(*)                                      AS "out_trace_count",
            COUNT(DISTINCT "to_address")                  AS "out_addr_count",
            SUM( CASE WHEN "value" <> 0 THEN 1 ELSE 0 END)           AS "out_transfer_count",
            AVG("value")/1e18                             AS "out_avg_amount",
            SUM("value")                                  AS "out_value_sum",
            SUM("receipt_gas_used" * "gas_price")         AS "fee_sum"
    FROM    tx_ok
    GROUP BY "from_address"
),
/* ---------- balance (ETH) -------------------------------*/
balance AS (
    SELECT  COALESCE(i."address", o."address")            AS "address",
            ( COALESCE(i."in_value_sum",0)
            - COALESCE(o."out_value_sum",0)
            - COALESCE(o."fee_sum",0) ) / 1e18            AS "balance"
    FROM    in_tx i
    FULL OUTER JOIN out_tx o  ON i."address" = o."address"
),
/* ------------------------------------------------------- */
/* 6. ERC‑20 token transfers                               */
token17 AS (
    SELECT * 
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt , const
    WHERE  tt."block_timestamp" < "ts_limit"
),
token_in AS (
    SELECT  "to_address"                                  AS "address",
            COUNT(*)                                      AS "token_in_tnx",
            COUNT(DISTINCT "token_address")               AS "token_in_type",
            COUNT(DISTINCT "from_address")                AS "token_from_addr"
    FROM    token17
    GROUP BY "to_address"
),
token_out AS (
    SELECT  "from_address"                                AS "address",
            COUNT(*)                                      AS "token_out_tnx",
            COUNT(DISTINCT "token_address")               AS "token_out_type",
            COUNT(DISTINCT "to_address")                  AS "token_to_addr"
    FROM    token17
    GROUP BY "from_address"
),
/* ------------------------------------------------------- */
/* 7. mining rewards                                       */
rewards AS (
    SELECT  t."to_address"                                AS "address",
            SUM(t."value")/1e18                           AS "reward_amount"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES" t , const
    WHERE   t."block_timestamp" < "ts_limit"
      AND   t."trace_type" = 'reward'
    GROUP BY t."to_address"
),
/* ------------------------------------------------------- */
/* 8. contract creations (tx root)                         */
contract_create AS (
    SELECT  "from_address"                                AS "address",
            COUNT(*)                                      AS "contract_create_count"
    FROM    tx_ok
    WHERE   "receipt_contract_address" IS NOT NULL
    GROUP BY "from_address"
),
/* ------------------------------------------------------- */
/* 9. failed tx counts                                     */
failures AS (
    SELECT  "from_address"                                AS "address",
            COUNT(*)                                      AS "failure_count"
    FROM    tx_fail
    GROUP BY "from_address"
),
/* ------------------------------------------------------- */
/* 10. byte‑code size for contract addresses               */
bytecode AS (
    SELECT  c."address",
            LENGTH(c."bytecode")                          AS "bytecode_size"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."CONTRACTS" c , const
    WHERE   c."block_timestamp" < "ts_limit"
)
/* ------------------------------------------------------- */
/* 11. final assembly                                      */
SELECT  a."address",

        /* ---- Balances & activity ---- */
        COALESCE(b."balance",0)                           AS "balance",
        a."R_active_hour",
        a."active_days",

        /* ---- Incoming ETH ---- */
        COALESCE(i."in_trace_count",0)                    AS "in_trace_count",
        COALESCE(i."in_addr_count",0)                     AS "in_addr_count",
        COALESCE(i."in_transfer_count",0)                 AS "in_transfer_count",
        COALESCE(i."in_avg_amount",0)                     AS "in_avg_amount",
        COALESCE(g."avg_gas_used",0)                      AS "avg_gas_used",
        COALESCE(g."std_gas_used",0)                      AS "std_gas_used",

        /* ---- Outgoing ETH ---- */
        COALESCE(o."out_trace_count",0)                   AS "out_trace_count",
        COALESCE(o."out_addr_count",0)                    AS "out_addr_count",
        COALESCE(o."out_transfer_count",0)                AS "out_transfer_count",
        COALESCE(o."out_avg_amount",0)                    AS "out_avg_amount",

        /* ---- Token stats ---- */
        COALESCE(ti."token_in_tnx",0)                     AS "token_in_tnx",
        COALESCE(ti."token_in_type",0)                    AS "token_in_type",
        COALESCE(ti."token_from_addr",0)                  AS "token_from_addr",
        COALESCE(too."token_out_tnx",0)                   AS "token_out_tnx",
        COALESCE(too."token_out_type",0)                  AS "token_out_type",
        COALESCE(too."token_to_addr",0)                   AS "token_to_addr",

        /* ---- Mining / contract / failures / bytecode --- */
        COALESCE(r."reward_amount",0)                     AS "reward_amount",
        COALESCE(cc."contract_create_count",0)            AS "contract_create_count",
        COALESCE(f."failure_count",0)                     AS "failure_count",
        COALESCE(bc."bytecode_size",0)                    AS "bytecode_size"

FROM        activity_stats a
LEFT JOIN   balance             b   ON a."address" = b."address"
LEFT JOIN   in_tx               i   ON a."address" = i."address"
LEFT JOIN   out_tx              o   ON a."address" = o."address"
LEFT JOIN   in_call_gas         g   ON a."address" = g."address"
LEFT JOIN   token_in            ti  ON a."address" = ti."address"
LEFT JOIN   token_out           too ON a."address" = too."address"
LEFT JOIN   rewards             r   ON a."address" = r."address"
LEFT JOIN   contract_create     cc  ON a."address" = cc."address"
LEFT JOIN   failures            f   ON a."address" = f."address"
LEFT JOIN   bytecode            bc  ON a."address" = bc."address"

ORDER BY    a."address";