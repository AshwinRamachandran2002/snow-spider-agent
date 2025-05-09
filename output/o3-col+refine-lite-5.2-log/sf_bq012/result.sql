WITH incoming AS (   -- successful native ETH sent TO an address
    SELECT
        "to_address"                         AS "addr",
        SUM("value")                         AS "incoming_wei"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "status" = 1
      AND  "trace_type" = 'call'
      AND  COALESCE("call_type",'') NOT IN ('delegatecall','callcode','staticcall')
      AND  "to_address" IS NOT NULL
    GROUP BY 1
),
outgoing AS (        -- successful native ETH sent FROM an address
    SELECT
        "from_address"                       AS "addr",
        SUM("value")                         AS "outgoing_wei"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "status" = 1
      AND  "trace_type" = 'call'
      AND  COALESCE("call_type",'') NOT IN ('delegatecall','callcode','staticcall')
      AND  "from_address" IS NOT NULL
    GROUP BY 1
),
rewards AS (         -- miner rewards
    SELECT
        "to_address"                         AS "addr",
        SUM("value")                         AS "reward_wei"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "trace_type" = 'reward'
      AND  "to_address" IS NOT NULL
    GROUP BY 1
),
gas_fees AS (        -- gas fees paid by each sender
    SELECT
        "from_address"                       AS "addr",
        SUM(("gas_price" * "receipt_gas_used")::NUMBER(38,0)) AS "gas_fee_wei"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE  "receipt_gas_used" IS NOT NULL
      AND  "gas_price"        IS NOT NULL
      AND  "from_address"     IS NOT NULL
    GROUP BY 1
),
-- collect a complete list of addresses seen in any component
addresses AS (
    SELECT "addr" FROM incoming
    UNION
    SELECT "addr" FROM outgoing
    UNION
    SELECT "addr" FROM rewards
    UNION
    SELECT "addr" FROM gas_fees
),
-- compute net balance for every address
totals AS (
    SELECT
        a."addr",
        COALESCE(i."incoming_wei",0)
      - COALESCE(o."outgoing_wei",0)
      + COALESCE(r."reward_wei",  0)
      - COALESCE(g."gas_fee_wei", 0)          AS "net_wei"
    FROM  addresses a
    LEFT  JOIN incoming i ON a."addr" = i."addr"
    LEFT  JOIN outgoing o ON a."addr" = o."addr"
    LEFT  JOIN rewards  r ON a."addr" = r."addr"
    LEFT  JOIN gas_fees g ON a."addr" = g."addr"
    WHERE a."addr" NOT ILIKE '0x0000000000000000000000000000000000000000'
),
-- rank by net balance
ranked AS (
    SELECT
        "addr",
        "net_wei",
        ROW_NUMBER() OVER (ORDER BY "net_wei" DESC NULLS LAST) AS rn
    FROM totals
),
top10 AS (
    SELECT "net_wei"
    FROM   ranked
    WHERE  rn <= 10
)
-- calculate average balance (10^15 Wei = quadrillion Wei) and round to 2 decimals
SELECT
    ROUND(AVG("net_wei") / 1e15, 2)  AS "average_balance_quadrillion"
FROM top10;