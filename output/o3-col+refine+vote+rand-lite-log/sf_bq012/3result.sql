/*  Average balance (in quadrillions Wei) of the 10 richest addresses
    – net balance = incoming value ‑ outgoing value ‑ sender gas fees + miner income
*/
WITH
/* 1. Incoming ETH for every address (successful, simple CALL traces) */
incoming AS (
    SELECT
        "to_address"             AS "address",
        SUM("value")             AS "wei_in"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status"      = 1
      AND "trace_type"  = 'call'
      AND ( "call_type" IS NULL OR "call_type" = 'call' )
      AND "to_address"  IS NOT NULL
    GROUP BY "to_address"
),
/* 2. Outgoing ETH for every address */
outgoing AS (
    SELECT
        "from_address"           AS "address",
        SUM("value")             AS "wei_out"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status"      = 1
      AND "trace_type"  = 'call'
      AND ( "call_type" IS NULL OR "call_type" = 'call' )
      AND "from_address" IS NOT NULL
    GROUP BY "from_address"
),
/* 3. Gas paid by senders */
gas_paid AS (
    SELECT
        "from_address"           AS "address",
        SUM("gas_price" * "receipt_gas_used") AS "gas_wei"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_gas_used" IS NOT NULL
      AND "from_address"     IS NOT NULL
    GROUP BY "from_address"
),
/* 4. Miner income = gas fees received + protocol rewards */
miner_income AS (
    SELECT
        b."miner"                AS "address",
        SUM( t."gas_price" * t."receipt_gas_used" )
        + SUM( COALESCE(r."value",0) )          AS "miner_income_wei"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS b
    LEFT JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t
           ON t."block_number" = b."number"
    LEFT JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES r
           ON r."block_number" = b."number"
          AND r."trace_type"   = 'reward'
    WHERE b."miner" IS NOT NULL
    GROUP BY b."miner"
),
/* 5. Combine components to get lifetime net balance per address */
net_balance AS (
    SELECT
        "address",
        COALESCE("wei_in",0)
      - COALESCE("wei_out",0)
      - COALESCE("gas_wei",0)
      + COALESCE("miner_income_wei",0)          AS "net_wei"
    FROM incoming
    FULL OUTER JOIN outgoing      USING ("address")
    FULL OUTER JOIN gas_paid      USING ("address")
    FULL OUTER JOIN miner_income  USING ("address")
    WHERE "address" IS NOT NULL
),
/* 6. Top-10 richest addresses */
top10 AS (
    SELECT "address", "net_wei"
    FROM   net_balance
    ORDER BY "net_wei" DESC NULLS LAST
    LIMIT 10
)
/* 7. Average of their balances, expressed in quadrillions Wei (10^15) */
SELECT
    ROUND( AVG( "net_wei" / 1e15 ), 2 ) AS "avg_balance_quadrillions"
FROM top10;