WITH
/* 1. Ether moved inside successful traces: negative for sender, positive for receiver */
trace_transfers AS (
    /* value sent (negative) */
    SELECT  LOWER("from_address")                                AS address ,
            -1 * COALESCE(CAST("value" AS NUMBER(38,0)),0)       AS amount
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE   "status" = 1
      AND   "trace_type" IN ('call','create','suicide')
      AND   ( "call_type" IS NULL
              OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND   "from_address" IS NOT NULL

    UNION ALL

    /* value received (positive) */
    SELECT  LOWER("to_address")                                  AS address ,
            COALESCE(CAST("value" AS NUMBER(38,0)),0)            AS amount
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE   "status" = 1
      AND   "trace_type" IN ('call','create','suicide')
      AND   ( "call_type" IS NULL
              OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND   "to_address" IS NOT NULL
),

/* 2. Gas‑fee flows: deducted from senders, credited to miners */
gas_fees AS (
    /* fee paid by the transaction sender (negative) */
    SELECT  LOWER(tx."from_address")                                                   AS address ,
            -1 * COALESCE(tx."gas_price",0) * COALESCE(tx."receipt_gas_used",0)        AS amount
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS tx
    WHERE   (tx."receipt_status" = 1 OR tx."receipt_status" IS NULL)
      AND   tx."from_address" IS NOT NULL

    UNION ALL

    /* fee received by the block miner (positive) */
    SELECT  LOWER(b."miner")                                                           AS address ,
            COALESCE(tx."gas_price",0) * COALESCE(tx."receipt_gas_used",0)             AS amount
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS tx
    JOIN    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS b
           ON tx."block_number" = b."number"
    WHERE   (tx."receipt_status" = 1 OR tx."receipt_status" IS NULL)
      AND   b."miner" IS NOT NULL
),

/* 3. Combine every balance‑affecting flow */
all_flows AS (
    SELECT * FROM trace_transfers
    UNION ALL
    SELECT * FROM gas_fees
),

/* 4. Net balance per address */
address_balances AS (
    SELECT  address ,
            SUM(amount) AS balance
    FROM    all_flows
    WHERE   address IS NOT NULL
    GROUP BY address
),

/* 5. Top‑10 addresses by balance */
top10 AS (
    SELECT  address , balance
    FROM    address_balances
    ORDER BY balance DESC NULLS LAST , address
    LIMIT   10
)

/* 6. Average balance (in quadrillions) of the top 10 */
SELECT  ROUND( AVG( balance / 1000000000000000 ) , 2 ) AS "AVG_BALANCE_QUADRILLIONS"
FROM    top10;