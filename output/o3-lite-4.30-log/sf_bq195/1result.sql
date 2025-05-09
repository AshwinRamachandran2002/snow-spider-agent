WITH vars AS (
    -- 2021‑09‑01 00:00:00 UTC in micro‑seconds and wei‑to‑ether divisor
    SELECT 1630454400000000::NUMBER AS ts_cutoff_micro,
           1000000000000000000::NUMBER AS wei_per_eth
),

/* -------------------------------------------------------------
   Layer‑1 transactions
------------------------------------------------------------- */
tx_out AS (   -- ether spent (value + gas fee)
    SELECT
        "from_address"                                           AS addr,
        SUM("value" + ("gas_price" * "receipt_gas_used"))        AS out_wei
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS", vars
    WHERE "receipt_status" = 1
      AND "block_timestamp" < vars.ts_cutoff_micro
    GROUP BY "from_address"
),
tx_in AS (    -- ether received (value only)
    SELECT
        "to_address"                                             AS addr,
        SUM("value")                                             AS in_wei
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS", vars
    WHERE "receipt_status" = 1
      AND "block_timestamp" < vars.ts_cutoff_micro
    GROUP BY "to_address"
),

/* -------------------------------------------------------------
   Internal value transfers (traces) – only NULL or 'call'
------------------------------------------------------------- */
trace_out AS (
    SELECT
        "from_address"                                           AS addr,
        SUM("value")                                             AS internal_out_wei
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES", vars
    WHERE "status" = 1
      AND ("call_type" IS NULL OR "call_type" = 'call')
      AND "block_timestamp" < vars.ts_cutoff_micro
    GROUP BY "from_address"
),
trace_in AS (
    SELECT
        "to_address"                                             AS addr,
        SUM("value")                                             AS internal_in_wei
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES", vars
    WHERE "status" = 1
      AND ("call_type" IS NULL OR "call_type" = 'call')
      AND "block_timestamp" < vars.ts_cutoff_micro
    GROUP BY "to_address"
),

/* -------------------------------------------------------------
   Combine all parts per address
------------------------------------------------------------- */
balances AS (
    SELECT
        COALESCE(tx_out.addr, tx_in.addr, trace_out.addr, trace_in.addr) AS address,
        COALESCE(tx_in.in_wei,              0) +
        COALESCE(trace_in.internal_in_wei,  0) -
        COALESCE(tx_out.out_wei,            0) -
        COALESCE(trace_out.internal_out_wei,0)                             AS net_wei
    FROM tx_out
    FULL OUTER JOIN tx_in     ON tx_out.addr                            = tx_in.addr
    FULL OUTER JOIN trace_out ON COALESCE(tx_out.addr, tx_in.addr)      = trace_out.addr
    FULL OUTER JOIN trace_in  ON COALESCE(tx_out.addr, tx_in.addr, trace_out.addr)
                              = trace_in.addr
)

/* -------------------------------------------------------------
   Final result: convert to ether, keep 4 decimals, top 10
------------------------------------------------------------- */
SELECT
    address,
    ROUND(net_wei / vars.wei_per_eth, 4) AS balance_ether
FROM balances, vars
WHERE address IS NOT NULL
ORDER BY balance_ether DESC NULLS LAST
LIMIT 10;