WITH
/* ------------------------------------------------------------------
   ETH value transfers coming from successful traces
   (exclude delegatecall / callcode / staticcall)
------------------------------------------------------------------ */
trace_transfers AS (
    /* credits ----------------------------------------------------- */
    SELECT  LOWER("to_address")   AS address,
            SUM(CAST("value" AS NUMBER(38,0)))             AS delta
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE   "status" = 1
      AND  ( "call_type" IS NULL
             OR LOWER("call_type") NOT IN ('delegatecall','callcode','staticcall') )
      AND   "to_address" IS NOT NULL
      AND   "to_address" <> '0x0000000000000000000000000000000000000000'
      AND   "value" IS NOT NULL
    GROUP BY LOWER("to_address")

    UNION ALL

    /* debits ------------------------------------------------------ */
    SELECT  LOWER("from_address") AS address,
           -SUM(CAST("value" AS NUMBER(38,0)))             AS delta
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE   "status" = 1
      AND  ( "call_type" IS NULL
             OR LOWER("call_type") NOT IN ('delegatecall','callcode','staticcall') )
      AND   "from_address" IS NOT NULL
      AND   "from_address" <> '0x0000000000000000000000000000000000000000'
      AND   "value" IS NOT NULL
    GROUP BY LOWER("from_address")
),

/* ------------------------------------------------------------------
   Gas‑fee deductions for transaction senders
------------------------------------------------------------------ */
tx_gas_deductions AS (
    SELECT  LOWER("from_address") AS address,
           -SUM( COALESCE("receipt_gas_used",0) * COALESCE("gas_price",0) ) AS delta
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE   "from_address" IS NOT NULL
      AND   "from_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY LOWER("from_address")
),

/* ------------------------------------------------------------------
   Miner rewards = sum of gas fees in each block
------------------------------------------------------------------ */
miner_rewards AS (
    SELECT  LOWER(b."miner")      AS address,
            SUM( COALESCE(t."receipt_gas_used",0) * COALESCE(t."gas_price",0) ) AS delta
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t
    JOIN    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS       b
           ON b."number" = t."block_number"
    WHERE   b."miner" IS NOT NULL
      AND   b."miner" <> '0x0000000000000000000000000000000000000000'
    GROUP BY LOWER(b."miner")
),

/* ------------------------------------------------------------------
   Combine every balance‑changing delta
------------------------------------------------------------------ */
all_deltas AS (
    SELECT * FROM trace_transfers
    UNION ALL
    SELECT * FROM tx_gas_deductions
    UNION ALL
    SELECT * FROM miner_rewards
),

/* ------------------------------------------------------------------
   Net balance per address
------------------------------------------------------------------ */
balance_by_address AS (
    SELECT  address,
            SUM(delta) AS balance_wei
    FROM    all_deltas
    GROUP BY address
),

/* ------------------------------------------------------------------
   Top‑10 richest addresses
------------------------------------------------------------------ */
top10 AS (
    SELECT  address,
            balance_wei
    FROM    balance_by_address
    ORDER BY balance_wei DESC NULLS LAST
    LIMIT 10
)

/* ------------------------------------------------------------------
   Final result: average balance in quadrillions of Wei (10^15)
------------------------------------------------------------------ */
SELECT  ROUND( AVG(balance_wei) / 1e15 , 2 )  AS "AVERAGE_BALANCE_QUADRILLIONS"
FROM    top10;