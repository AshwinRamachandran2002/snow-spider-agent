WITH traces_filtered AS (           -- only successful value‑transferring calls
    SELECT
        "to_address",
        "from_address",
        "value"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES"
    WHERE "status" = 1
      AND "trace_type" = 'call'
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
),               -- incoming / outgoing ether per address
trace_in AS (
    SELECT "to_address" AS "address",
           SUM("value") AS "in_wei"
    FROM traces_filtered
    WHERE "to_address" IS NOT NULL
    GROUP BY "to_address"
),
trace_out AS (
    SELECT "from_address" AS "address",
           SUM("value") AS "out_wei"
    FROM traces_filtered
    WHERE "from_address" IS NOT NULL
    GROUP BY "from_address"
),               -- gas fees paid by senders
gas_paid AS (
    SELECT "from_address" AS "address",
           SUM("gas_price" * "receipt_gas_used") AS "gas_paid_wei"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS"
    WHERE "receipt_status" = 1
      AND "from_address" IS NOT NULL
    GROUP BY "from_address"
),               -- gas fees earned by miners
gas_earned AS (
    SELECT b."miner" AS "address",
           SUM(t."gas_price" * t."receipt_gas_used") AS "gas_reward_wei"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."BLOCKS"        b
    JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS"  t
      ON b."number" = t."block_number"
    WHERE t."receipt_status" = 1
      AND b."miner" IS NOT NULL
    GROUP BY b."miner"
),               -- universe of addresses
all_addresses AS (
    SELECT "address" FROM trace_in
    UNION
    SELECT "address" FROM trace_out
    UNION
    SELECT "address" FROM gas_paid
    UNION
    SELECT "address" FROM gas_earned
),               -- merge all balance components
combined AS (
    SELECT
        a."address",
        COALESCE(i."in_wei",         0) AS "in_wei",
        COALESCE(o."out_wei",        0) AS "out_wei",
        COALESCE(p."gas_paid_wei",   0) AS "gas_paid_wei",
        COALESCE(e."gas_reward_wei", 0) AS "gas_reward_wei"
    FROM all_addresses a
    LEFT JOIN trace_in  i ON a."address" = i."address"
    LEFT JOIN trace_out o ON a."address" = o."address"
    LEFT JOIN gas_paid  p ON a."address" = p."address"
    LEFT JOIN gas_earned e ON a."address" = e."address"
)                -- average (in 10^15 wei) of the 10 richest addresses
SELECT ROUND(AVG("net_balance_qt"), 2) AS average_balance_quadrillions
FROM (
    SELECT
        ( "in_wei" - "out_wei" - "gas_paid_wei" + "gas_reward_wei") / 1e15
        AS "net_balance_qt"
    FROM combined
    WHERE "address" IS NOT NULL
      AND "address" <> '0x0000000000000000000000000000000000000000'
    ORDER BY ( "in_wei" - "out_wei" - "gas_paid_wei" + "gas_reward_wei")
             DESC NULLS LAST
    LIMIT 10
);