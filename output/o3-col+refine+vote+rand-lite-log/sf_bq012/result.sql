WITH value_transfers AS (          -- successful ETH transfers coming from TRACES
    SELECT 
        "from_address"                        AS "address",
        -SUM("value")                         AS "net_change"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "trace_type" = 'call'
      AND  "status"      = 1
      AND  ("call_type" IS NULL OR "call_type" = 'call')     -- exclude delegatecall/callcode/staticcall
      AND  "from_address" IS NOT NULL
      AND  "to_address"   IS NOT NULL
    GROUP BY "from_address"

    UNION ALL

    SELECT 
        "to_address"                          AS "address",
        SUM("value")                          AS "net_change"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "trace_type" = 'call'
      AND  "status"      = 1
      AND  ("call_type" IS NULL OR "call_type" = 'call')
      AND  "from_address" IS NOT NULL
      AND  "to_address"   IS NOT NULL
    GROUP BY "to_address"
),

gas_fees AS (                        -- sender deductions  & miner rewards
    /* sender gas-fee deductions */
    SELECT  
        t."from_address"                     AS "address",
        -CAST(t."gas_price" * t."receipt_gas_used" AS NUMBER(38,0))   AS "net_change"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t
    WHERE   t."receipt_gas_used" IS NOT NULL
      AND   t."from_address"      IS NOT NULL
    
    UNION ALL
    
    /* miner gas-fee rewards */
    SELECT  
        b."miner"                            AS "address",
        CAST(t."gas_price" * t."receipt_gas_used"  AS NUMBER(38,0))   AS "net_change"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t
    JOIN    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS       b
           ON t."block_hash" = b."hash"
    WHERE   t."receipt_gas_used" IS NOT NULL
      AND   b."miner"            IS NOT NULL
),

all_flows AS (
    SELECT * FROM value_transfers
    UNION ALL
    SELECT * FROM gas_fees
),

balances AS (                       -- net balance per address
    SELECT 
        "address",
        SUM("net_change")           AS "net_balance"
    FROM   all_flows
    WHERE  "address" IS NOT NULL
      AND  "address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "address"
),

top10 AS (                          -- richest 10 addresses
    SELECT 
        "address",
        "net_balance"
    FROM   balances
    ORDER BY "net_balance" DESC NULLS LAST
    LIMIT  10
)

SELECT 
    ROUND(AVG("net_balance" / 1000000000000000), 2)  AS "average_balance_in_quadrillions"
FROM   top10;