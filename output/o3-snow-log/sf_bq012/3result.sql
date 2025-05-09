WITH
-- 1. Value-moving traces (only successful & allowed call types)
trace_flows AS (
    SELECT
        "to_address"  AS address,
        SUM("value")  AS amount
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
    WHERE "value" > 0
      AND "status" = 1
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND "to_address" IS NOT NULL
    GROUP BY "to_address"

    UNION ALL

    SELECT
        "from_address" AS address,
        -SUM("value")  AS amount
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
    WHERE "value" > 0
      AND "status" = 1
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND "from_address" IS NOT NULL
    GROUP BY "from_address"
),

-- 2. Sender gas-fee deductions (outgoing)
sender_fees AS (
    SELECT
        "from_address"                 AS address,
        -SUM("gas_price" * "receipt_gas_used") AS amount
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRANSACTIONS"
    WHERE "receipt_status" = 1
      AND "receipt_gas_used" IS NOT NULL
      AND "from_address" IS NOT NULL
    GROUP BY "from_address"
),

-- 3. Miner gas-fee rewards (incoming)
miner_fees AS (
    SELECT
        b."miner"                      AS address,
        SUM(t."gas_price" * t."receipt_gas_used") AS amount
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRANSACTIONS" t
    JOIN "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."BLOCKS" b
      ON t."block_hash" = b."hash"
    WHERE t."receipt_status" = 1
      AND t."receipt_gas_used" IS NOT NULL
      AND b."miner" IS NOT NULL
    GROUP BY b."miner"
),

-- 4. Combine all monetary flows
all_flows AS (
    SELECT * FROM trace_flows
    UNION ALL
    SELECT * FROM sender_fees
    UNION ALL
    SELECT * FROM miner_fees
),

-- 5. Net balance per address
net_balances AS (
    SELECT
        address,
        SUM(amount) AS net_balance
    FROM all_flows
    WHERE address IS NOT NULL
      AND address <> '0x0000000000000000000000000000000000000000'
    GROUP BY address
),

-- 6. Top-10 addresses by net balance
top10 AS (
    SELECT net_balance
    FROM net_balances
    ORDER BY net_balance DESC NULLS LAST
    LIMIT 10
)

-- 7. Average balance in quadrillions (10^15), rounded to 2 decimals
SELECT
    ROUND( AVG(net_balance) / 1000000000000000 , 2) AS "average_balance_quadrillions"
FROM top10;