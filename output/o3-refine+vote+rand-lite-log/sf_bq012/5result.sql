WITH trace_transfers AS (   -- ether moved inside successful calls
    SELECT
        LOWER("from_address")                     AS from_address,
        LOWER("to_address")                       AS to_address,
        "value"::NUMBER(38,0)                     AS value_wei
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
    WHERE "status" = 1
      AND "trace_type" = 'call'
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND "value"::NUMBER(38,0) > 0
      AND "from_address" IS NOT NULL
      AND "to_address" IS NOT NULL
      AND LOWER("from_address") <> '0x0000000000000000000000000000000000000000'
      AND LOWER("to_address")   <> '0x0000000000000000000000000000000000000000'
),
trace_flows AS (          -- positive for receiver, negative for sender
    SELECT from_address AS address, -value_wei AS amount FROM trace_transfers
    UNION ALL
    SELECT to_address   AS address,  value_wei AS amount FROM trace_transfers
),
tx_gas AS (               -- gas fees paid by senders in each tx
    SELECT
        LOWER("from_address")                                      AS from_address,
        "block_number",
        (COALESCE("receipt_gas_used",0) * COALESCE("gas_price",0))::NUMBER(38,0) AS gas_fee
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRANSACTIONS"
    WHERE "from_address" IS NOT NULL
      AND LOWER("from_address") <> '0x0000000000000000000000000000000000000000'
),
sender_gas AS (           -- deduct gas fee from sender
    SELECT from_address AS address, -gas_fee AS amount
    FROM tx_gas
    WHERE gas_fee > 0
),
block_gas_fee AS (        -- total gas fee per block
    SELECT "block_number", SUM(gas_fee) AS total_gas_fee
    FROM tx_gas
    GROUP BY "block_number"
),
miner_rewards AS (        -- pay the miner the total gas fee per block
    SELECT
        LOWER(b."miner")     AS address,
        bg.total_gas_fee     AS amount
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."BLOCKS" b
    JOIN block_gas_fee bg
      ON b."number" = bg."block_number"
    WHERE b."miner" IS NOT NULL
      AND LOWER(b."miner") <> '0x0000000000000000000000000000000000000000'
),
all_flows AS (            -- union all monetary movements
    SELECT * FROM trace_flows
    UNION ALL
    SELECT * FROM sender_gas
    UNION ALL
    SELECT * FROM miner_rewards
),
balances AS (             -- net balance per address
    SELECT address, SUM(amount) AS net_balance
    FROM all_flows
    GROUP BY address
),
top10 AS (                -- top 10 richest addresses
    SELECT address, net_balance
    FROM balances
    ORDER BY net_balance DESC NULLS LAST
    LIMIT 10
)
SELECT
    ROUND(AVG(net_balance / 1e15), 2) AS "average_balance_in_quadrillions"
FROM top10;