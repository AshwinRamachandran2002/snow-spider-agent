WITH
-- 1.  Cut-off timestamp for 2021-09-01 00:00:00 UTC (micro-seconds)
cutoff AS (
    SELECT 1630454400000000 AS ts
),

-- 2.  Address that sent the most successful transactions before the cut-off
top_sender AS (
    SELECT  "from_address" AS address
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
            , cutoff
    WHERE   t."receipt_status" = 1
      AND   t."block_timestamp" < cutoff.ts
    GROUP BY "from_address"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),

-- 3.  Outgoing native value and gas costs
outgoing AS (
    SELECT
        SUM(t."value")                                                   AS out_value_wei,
        SUM( COALESCE(t."receipt_effective_gas_price", t."gas_price")
             * t."receipt_gas_used")                                     AS gas_cost_wei
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
           JOIN cutoff     ON 1=1
           JOIN top_sender ON t."from_address" = top_sender.address
    WHERE  t."receipt_status" = 1
      AND  t."block_timestamp" < cutoff.ts
),

-- 4.  Incoming native value
incoming AS (
    SELECT  SUM(t."value") AS in_value_wei
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
            JOIN cutoff     ON 1=1
            JOIN top_sender ON t."to_address" = top_sender.address
    WHERE   t."receipt_status" = 1
      AND   t."block_timestamp" < cutoff.ts
),

-- 5.  Miner / uncle rewards to that address
rewards AS (
    SELECT  SUM(tr."value") AS reward_wei
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRACES tr
            JOIN cutoff     ON 1=1
            JOIN top_sender ON tr."to_address" = top_sender.address
    WHERE   tr."trace_type" = 'reward'
      AND   tr."block_timestamp" < cutoff.ts
)

-- 6.  Final Ether balance (Wei → Ether)
SELECT
    top_sender.address,
    ROUND(
        (COALESCE(incoming.in_value_wei , 0) +
         COALESCE(rewards.reward_wei   , 0) -
         COALESCE(outgoing.out_value_wei, 0) -
         COALESCE(outgoing.gas_cost_wei, 0)
        ) / 1e18 , 4)        AS final_balance_eth
FROM  top_sender
LEFT JOIN outgoing ON 1=1
LEFT JOIN incoming ON 1=1
LEFT JOIN rewards  ON 1=1;