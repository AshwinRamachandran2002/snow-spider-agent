/* -----------------------------------------------------------------
   Comprehensive address‑level report for all activity **before
   2017‑01‑01**  (timestamps are stored in µs → 1483228800000000)
   Every ETH amount is divided by 1e18 to convert Wei → Ether.
------------------------------------------------------------------*/

WITH
/*--------------- 1.  Parameters ---------------------------------*/
params AS (
    SELECT 1483228800000000::NUMBER AS cutoff_ts          -- 2017‑01‑01 UTC, µs
),

/*--------------- 2.  Filtered traces (exclude delegate/callcode/staticcall) */
traces_filt AS (
    SELECT  *
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES t , params p
    WHERE   t."block_timestamp" < p.cutoff_ts
      AND  (t."call_type" IS NULL
            OR t."call_type" NOT IN ('delegatecall','callcode','staticcall'))
),

/*--------------- 3.  Incoming & outgoing trace aggregates --------*/
in_traces AS (
    SELECT  "to_address"                               AS address,
            COUNT(*)                                   AS in_trace_count,
            COUNT(DISTINCT "from_address")             AS in_addr_count,
            SUM(CASE WHEN "value" <> 0 THEN 1 ELSE 0 END)  AS in_transfer_count,
            AVG("value"/1e18)                          AS in_avg_amount,
            AVG(CASE WHEN "trace_type"='call' THEN "gas_used" END)           AS avg_gas_used,
            STDDEV_SAMP(CASE WHEN "trace_type"='call' THEN "gas_used" END)   AS std_gas_used,
            SUM("value")                               AS in_total_value
    FROM    traces_filt
    WHERE   "to_address" IS NOT NULL
    GROUP BY "to_address"
),
out_traces AS (
    SELECT  "from_address"                             AS address,
            COUNT(*)                                   AS out_trace_count,
            COUNT(DISTINCT "to_address")               AS out_addr_count,
            SUM(CASE WHEN "value" <> 0 THEN 1 ELSE 0 END)  AS out_transfer_count,
            AVG("value"/1e18)                          AS out_avg_amount,
            SUM("value")                               AS out_total_value
    FROM    traces_filt
    WHERE   "from_address" IS NOT NULL
    GROUP BY "from_address"
),

/*--------------- 4.  Transaction fees (successful ext‑tx only) ---*/
tx_fees AS (
    SELECT  "from_address" AS address,
            SUM("gas_price" * "receipt_gas_used") AS total_fee
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS tx , params p
    WHERE   tx."block_timestamp" < p.cutoff_ts
      AND   tx."receipt_status" = 1
    GROUP BY "from_address"
),

/*--------------- 5.  Mining rewards -----------------------------*/
rewards AS (
    SELECT  "to_address" AS address,
            SUM("value") AS reward_value
    FROM    traces_filt
    WHERE   "trace_type" = 'reward'
    GROUP BY "to_address"
),

/*--------------- 6.  Contract creations & byte‑code size ---------*/
contract_creates AS (
    SELECT  "from_address" AS address,
            COUNT(*)       AS contract_create_count
    FROM    traces_filt
    WHERE   "trace_type" = 'create'
    GROUP BY "from_address"
),
bytecode_raw AS (  -- contracts whose creation is before the cut‑off
    SELECT  "address",
            LENGTH("bytecode") AS bc_size
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.CONTRACTS c , params p
    WHERE   c."block_timestamp" < p.cutoff_ts
),
bytecode_size AS (
    /* average byte‑code length of contracts created by each creator */
    SELECT  t."from_address" AS address,
            AVG(b.bc_size)   AS bytecode_size
    FROM    traces_filt        t
    JOIN    bytecode_raw       b
          ON b."address" = t."to_address"
    WHERE   t."trace_type" = 'create'
    GROUP BY t."from_address"
),

/*--------------- 7.  Failed transactions ------------------------*/
failures AS (
    SELECT  "from_address" AS address,
            COUNT(*)       AS failure_count
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS tx , params p
    WHERE   tx."block_timestamp" < p.cutoff_ts
      AND   tx."receipt_status" = 0
    GROUP BY "from_address"
),

/*--------------- 8.  ERC‑20 token transfer aggregates ------------*/
token_transfers_cut AS (
    SELECT *
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS tt , params p
    WHERE  tt."block_timestamp" < p.cutoff_ts
),
token_in AS (
    SELECT  "to_address"                        AS address,
            COUNT(*)                            AS token_in_tnx,
            COUNT(DISTINCT "token_address")     AS token_in_type,
            COUNT(DISTINCT "from_address")      AS token_from_addr
    FROM    token_transfers_cut
    GROUP BY "to_address"
),
token_out AS (
    SELECT  "from_address"                      AS address,
            COUNT(*)                            AS token_out_tnx,
            COUNT(DISTINCT "token_address")     AS token_out_type,
            COUNT(DISTINCT "to_address")        AS token_to_addr
    FROM    token_transfers_cut
    GROUP BY "from_address"
),

/*--------------- 9.  Activity events for hour‑pattern + days -----*/
activity_events AS (
    SELECT  "from_address" AS address, "block_timestamp" FROM traces_filt WHERE "from_address" IS NOT NULL
    UNION ALL
    SELECT  "to_address"   AS address, "block_timestamp" FROM traces_filt WHERE "to_address"   IS NOT NULL
),
activity_stats AS (
    SELECT  address,
            COUNT(*)                                                     AS activity_count,
            COUNT(DISTINCT TO_DATE( TO_TIMESTAMP("block_timestamp"/1e6) )) AS active_days,
            /* Hourly uniformity – R_active_hour */
            SQRT( POWER(SUM( COS( 2*PI()*EXTRACT(HOUR FROM TO_TIMESTAMP("block_timestamp"/1e6))/24 )),2 ) +
                  POWER(SUM( SIN( 2*PI()*EXTRACT(HOUR FROM TO_TIMESTAMP("block_timestamp"/1e6))/24 )),2 ) )
              / COUNT(*)                                                 AS R_active_hour
    FROM    activity_events
    GROUP BY address
),

/*-------------- 10.  Net balance (Ether) -------------------------*/
balance_calc AS (
    SELECT  COALESCE(i.address,o.address,f.address)  AS address,
            COALESCE(i.in_total_value ,0)            AS incoming,
            COALESCE(o.out_total_value,0)            AS outgoing,
            COALESCE(f.total_fee       ,0)           AS fees
    FROM    in_traces   i
    FULL OUTER JOIN out_traces o  ON i.address = o.address
    FULL OUTER JOIN tx_fees   f   ON COALESCE(i.address,o.address) = f.address
),
balances AS (
    SELECT  address,
            (incoming - outgoing - fees)/1e18  AS balance
    FROM    balance_calc
)

/*--------------- 11.  Final assembly -----------------------------*/
SELECT
        adr.address                                     AS address
      , COALESCE(bal.balance,0)                         AS balance
      , act.R_active_hour
      , act.active_days
      , in_t.in_trace_count
      , in_t.in_addr_count
      , in_t.in_transfer_count
      , in_t.in_avg_amount
      , in_t.avg_gas_used
      , in_t.std_gas_used
      , out_t.out_trace_count
      , out_t.out_addr_count
      , out_t.out_transfer_count
      , out_t.out_avg_amount
      , tok_in.token_in_tnx
      , tok_in.token_in_type
      , tok_in.token_from_addr
      , tok_out.token_out_tnx
      , tok_out.token_out_type
      , tok_out.token_to_addr
      , COALESCE(rew.reward_value,0)/1e18              AS reward_amount
      , COALESCE(cc.contract_create_count,0)           AS contract_create_count
      , COALESCE(fail.failure_count,0)                 AS failure_count
      , byte.bytecode_size
FROM  (
        /* union of every address that showed any pre‑2017 activity */
        SELECT DISTINCT address FROM (
            SELECT address FROM in_traces
            UNION
            SELECT address FROM out_traces
            UNION
            SELECT address FROM token_in
            UNION
            SELECT address FROM token_out
            UNION
            SELECT address FROM rewards
            UNION
            SELECT address FROM contract_creates
            UNION
            SELECT address FROM failures
        )
      )                adr
LEFT JOIN balances        bal    ON adr.address = bal.address
LEFT JOIN activity_stats  act    ON adr.address = act.address
LEFT JOIN in_traces       in_t   ON adr.address = in_t.address
LEFT JOIN out_traces      out_t  ON adr.address = out_t.address
LEFT JOIN token_in        tok_in ON adr.address = tok_in.address
LEFT JOIN token_out       tok_out ON adr.address = tok_out.address
LEFT JOIN rewards         rew    ON adr.address = rew.address
LEFT JOIN contract_creates cc    ON adr.address = cc.address
LEFT JOIN failures        fail   ON adr.address = fail.address
LEFT JOIN bytecode_size   byte   ON adr.address = byte.address;