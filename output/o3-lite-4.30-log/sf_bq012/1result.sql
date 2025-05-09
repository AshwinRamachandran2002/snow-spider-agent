WITH incoming AS (      -- positive: ether received via successful traces
    SELECT
        "to_address"                                   AS "address",
        SUM("value")                                   AS "amount_wei"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status" = 1
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND "to_address" IS NOT NULL
      AND "to_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "to_address"
),
outgoing AS (          -- negative: ether sent via successful traces
    SELECT
        "from_address"                                 AS "address",
       -SUM("value")                                   AS "amount_wei"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status" = 1
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND "from_address" IS NOT NULL
      AND "from_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "from_address"
),
gas_paid AS (          -- negative: gas fees paid by transaction senders
    SELECT
        "from_address"                                 AS "address",
       -SUM("gas_price" * "receipt_gas_used")          AS "amount_wei"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_gas_used" IS NOT NULL
      AND "from_address" IS NOT NULL
      AND "from_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "from_address"
),
gas_earned AS (        -- positive: gas fees earned by miners
    SELECT
        b."miner"                                      AS "address",
        SUM(t."gas_price" * t."receipt_gas_used")      AS "amount_wei"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS       b
    JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t
      ON b."hash" = t."block_hash"
    WHERE t."receipt_gas_used" IS NOT NULL
      AND b."miner" IS NOT NULL
      AND b."miner" <> '0x0000000000000000000000000000000000000000'
    GROUP BY b."miner"
),
all_movements AS (
    SELECT * FROM incoming
    UNION ALL
    SELECT * FROM outgoing
    UNION ALL
    SELECT * FROM gas_paid
    UNION ALL
    SELECT * FROM gas_earned
),
net_balances AS (
    SELECT
        "address",
        SUM("amount_wei") AS "net_wei"
    FROM all_movements
    GROUP BY "address"
),
top10 AS (
    SELECT
        "net_wei"
    FROM net_balances
    ORDER BY "net_wei" DESC NULLS LAST
    LIMIT 10
)
SELECT
    ROUND( AVG("net_wei") / 1000000000000000 , 2) AS "average_balance_quadrillions"
FROM top10;