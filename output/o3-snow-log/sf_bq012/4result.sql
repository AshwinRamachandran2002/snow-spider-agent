/* average balance (in quadrillions) of the 10 richest addresses */
WITH successful_traces AS (          -- ETH moves (only successful, no delegated/static/callcode)
    SELECT
        "to_address"      AS "address",
        "value"           AS "amount"
    FROM   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
    WHERE  "trace_type" = 'call'
      AND  "status" = 1
      AND  ( "call_type" IS NULL 
             OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND  "to_address" IS NOT NULL

    UNION ALL

    SELECT
        "from_address"    AS "address",
        - "value"         AS "amount"
    FROM   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
    WHERE  "trace_type" = 'call'
      AND  "status" = 1
      AND  ( "call_type" IS NULL 
             OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND  "from_address" IS NOT NULL
),
tx_sender_fees AS (                 -- gas fees paid by senders (deduction)
    SELECT
        "from_address"                                 AS "address",
        - ("gas_price" * "receipt_gas_used")           AS "amount"
    FROM   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRANSACTIONS"
    WHERE  "receipt_status" = 1
      AND  "gas_price" IS NOT NULL
      AND  "receipt_gas_used" IS NOT NULL
      AND  "from_address" IS NOT NULL
),
block_miner_fees AS (               -- miners receive total fees in each block
    SELECT
        b."miner"                                         AS "address",
        SUM(t."gas_price" * t."receipt_gas_used")         AS "amount"
    FROM   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRANSACTIONS"  t
    JOIN   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."BLOCKS"        b
           ON t."block_hash" = b."hash"
    WHERE  t."receipt_status" = 1
      AND  t."gas_price" IS NOT NULL
      AND  t."receipt_gas_used" IS NOT NULL
      AND  b."miner" IS NOT NULL
    GROUP BY b."miner"
),
all_events AS (                    -- union everything
    SELECT * FROM successful_traces
    UNION ALL
    SELECT * FROM tx_sender_fees
    UNION ALL
    SELECT * FROM block_miner_fees
),
balances AS (                      -- net balance per address
    SELECT
        "address",
        SUM("amount") AS "balance_wei"
    FROM   all_events
    WHERE  "address" IS NOT NULL
    GROUP BY "address"
),
top10 AS (                         -- ten richest addresses
    SELECT
        "balance_wei"
    FROM   balances
    ORDER BY "balance_wei" DESC NULLS LAST
    LIMIT 10
)
SELECT
    ROUND( AVG("balance_wei") / 1000000000000000 , 2 )  AS "avg_balance_quadrillions"
FROM   top10;