WITH
-- 1. Address with the highest number of successful txs (before 2021‑09‑01 UTC)
"TOP_ADDR" AS (
    SELECT  "from_address"         AS "addr"
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE   "receipt_status" = 1
      AND   "block_timestamp" < 1630454400000000      -- 2021‑09‑01 00:00:00 UTC (μs)
    GROUP BY "from_address"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),

-- 2. Outgoing native transfers and gas fees
"TX_OUT" AS (
    SELECT
            SUM("value")                                                             AS "out_value_wei",
            SUM("receipt_gas_used" * COALESCE("receipt_effective_gas_price","gas_price")) 
                                                                                     AS "gas_fee_wei"
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t
    JOIN    "TOP_ADDR" a
           ON t."from_address" = a."addr"
),

-- 3. Incoming native transfers
"TX_IN"  AS (
    SELECT  SUM("value") AS "in_value_wei"
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t
    JOIN    "TOP_ADDR" a
           ON t."to_address" = a."addr"
),

-- 4. Miner rewards credited to the address (trace_type = 'reward')
"REWARDS" AS (
    SELECT  SUM("value") AS "reward_wei"
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRACES tr
    JOIN    "TOP_ADDR" a
           ON tr."to_address" = a."addr"
    WHERE   tr."trace_type" = 'reward'
),

-- 5. Assemble final balance in Wei
"BALANCE_WEI" AS (
    SELECT
        COALESCE(i."in_value_wei",   0) +
        COALESCE(r."reward_wei",     0) -
        COALESCE(o."out_value_wei",  0) -
        COALESCE(o."gas_fee_wei",    0)  AS "net_wei"
    FROM  "TX_IN"      i
    CROSS JOIN "TX_OUT" o
    CROSS JOIN "REWARDS" r
)

-- 6. Present result in Ether
SELECT
        a."addr"                                                     AS "ethereum_address",
        ("net_wei" / 1e18)                                           AS "final_balance_ether"
FROM    "TOP_ADDR"      a
JOIN    "BALANCE_WEI"   b
     ON 1=1;