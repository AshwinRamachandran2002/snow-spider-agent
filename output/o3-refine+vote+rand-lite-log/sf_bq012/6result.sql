WITH

/* -----------------------------------------------------------
 * 1.  ETH transfers recorded in TRACES (successful calls only)
 * -----------------------------------------------------------*/
"TRACE_TRANSFERS" AS (

    /* outgoing value (negative) */
    SELECT
        "from_address"               AS address,
        -SUM("value")                AS value_change
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "trace_type" = 'call'
      AND "status"     = 1
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND "from_address" IS NOT NULL
      AND "from_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "from_address"

    UNION ALL

    /* incoming value (positive) */
    SELECT
        "to_address"                 AS address,
        SUM("value")                 AS value_change
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "trace_type" = 'call'
      AND "status"     = 1
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND "to_address" IS NOT NULL
      AND "to_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "to_address"
),

/* -----------------------------------------------------------
 * 2.  Gas fees paid per transaction (sender deduction)
 * -----------------------------------------------------------*/
"SENDER_GAS_DEDUCTIONS" AS (
    SELECT
        "from_address"                                   AS address,
        -SUM( "receipt_gas_used" * "gas_price" )         AS value_change
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_gas_used" IS NOT NULL
      AND "gas_price"        IS NOT NULL
      AND "from_address"     IS NOT NULL
      AND "from_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "from_address"
),

/* -----------------------------------------------------------
 * 3.  Aggregate gas fees per block (later credited to miner)
 * -----------------------------------------------------------*/
"TX_GAS_PER_BLOCK" AS (
    SELECT
        "block_hash",
        SUM( "receipt_gas_used" * "gas_price" ) AS total_gas_fee
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_gas_used" IS NOT NULL
      AND "gas_price"        IS NOT NULL
    GROUP BY "block_hash"
),

/* -----------------------------------------------------------
 * 4.  Miner rewards = sum of gas fees of all txs in the block
 * -----------------------------------------------------------*/
"MINER_REWARDS" AS (
    SELECT
        b."miner"                                  AS address,
        SUM(g.total_gas_fee)                       AS value_change
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS      b
    JOIN "TX_GAS_PER_BLOCK"                        g
      ON g."block_hash" = b."hash"
    WHERE b."miner" IS NOT NULL
      AND b."miner" <> '0x0000000000000000000000000000000000000000'
    GROUP BY b."miner"
),

/* -----------------------------------------------------------
 * 5.  Union every monetary change
 * -----------------------------------------------------------*/
"ALL_CHANGES" AS (
    SELECT * FROM "TRACE_TRANSFERS"
    UNION ALL
    SELECT * FROM "SENDER_GAS_DEDUCTIONS"
    UNION ALL
    SELECT * FROM "MINER_REWARDS"
),

/* -----------------------------------------------------------
 * 6.  Net balance by address
 * -----------------------------------------------------------*/
"ADDRESS_BALANCES" AS (
    SELECT
        address,
        SUM(value_change) AS net_balance
    FROM "ALL_CHANGES"
    GROUP BY address
    HAVING net_balance IS NOT NULL
)

/* -----------------------------------------------------------
 * 7.  Average balance (in quadrillions, 1e15) of top‑10
 * -----------------------------------------------------------*/
SELECT
    ROUND( AVG(net_balance / 1e15), 2 ) AS "AVG_BALANCE_QUADRILLIONS"
FROM (
    SELECT
        net_balance
    FROM "ADDRESS_BALANCES"
    ORDER BY net_balance DESC NULLS LAST
    FETCH FIRST 10 ROWS
) AS top10;