WITH trace_transfers AS (   -- value movements coming from internal ETH transfers
    /* incoming value (credit) */
    SELECT 
        "to_address"                                    AS address,
        SUM(TO_NUMBER("value"))                         AS amount
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
    WHERE "status" = 1
      AND "trace_type" = 'call'
      AND ( "call_type" IS NULL OR "call_type" = 'call')
      AND "to_address" IS NOT NULL
      AND LOWER("to_address") <> '0x0000000000000000000000000000000000000000'
    GROUP BY "to_address"
    
    UNION ALL
    
    /* outgoing value (debit) */
    SELECT 
        "from_address"                                  AS address,
        -SUM(TO_NUMBER("value"))                        AS amount
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
    WHERE "status" = 1
      AND "trace_type" = 'call'
      AND ( "call_type" IS NULL OR "call_type" = 'call')
      AND "from_address" IS NOT NULL
      AND LOWER("from_address") <> '0x0000000000000000000000000000000000000000'
    GROUP BY "from_address"
),

/* gas fees paid by transaction senders (debit) */
gas_fees_sender AS (
    SELECT
        "from_address"                                  AS address,
        -SUM("receipt_gas_used" * "gas_price")          AS amount
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRANSACTIONS"
    WHERE "from_address" IS NOT NULL
      AND LOWER("from_address") <> '0x0000000000000000000000000000000000000000'
      AND "receipt_gas_used" IS NOT NULL
      AND "gas_price" IS NOT NULL
    GROUP BY "from_address"
),

/* gas fees earned by miners (credit) */
gas_fees_miner AS (
    SELECT
        blk."miner"                                     AS address,
        SUM(tx."receipt_gas_used" * tx."gas_price")     AS amount
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."BLOCKS"        blk
    JOIN "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRANSACTIONS"  tx
      ON blk."hash" = tx."block_hash"
    WHERE blk."miner" IS NOT NULL
      AND LOWER(blk."miner") <> '0x0000000000000000000000000000000000000000'
      AND tx."receipt_gas_used" IS NOT NULL
      AND tx."gas_price" IS NOT NULL
    GROUP BY blk."miner"
),

/* union every monetary movement */
all_movements AS (
    SELECT * FROM trace_transfers
    UNION ALL
    SELECT * FROM gas_fees_sender
    UNION ALL
    SELECT * FROM gas_fees_miner
),

/* aggregate to net balance per address */
balances AS (
    SELECT 
        address,
        SUM(amount) AS net_balance_wei
    FROM all_movements
    GROUP BY address
)

SELECT
    ROUND( AVG(net_balance_wei) / 1e15 , 2)  AS avg_balance_quadrillion
FROM (
    SELECT 
        net_balance_wei
    FROM balances
    ORDER BY net_balance_wei DESC NULLS LAST
    LIMIT 10
) top10;