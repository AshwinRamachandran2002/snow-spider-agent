/* Average balance (in quadrillions, 10^15 Wei) of the 10 richest addresses
   – incoming/outgoing ETH transfers (successful call-traces only)
   – minus sender gas costs
   – plus miners’ income from gas fees                                       */

WITH value_transfers AS (          -- 1) successful native-ETH transfers
    SELECT
        "from_address",
        "to_address",
        CAST("value" AS NUMBER)              AS "value_wei"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status"      = 1
      AND "trace_type"  = 'call'
      AND ("call_type" IS NULL OR "call_type" = 'call')
      AND "value"       > 0
),

transfer_deltas AS (               -- +value to receiver, –value from sender
    SELECT "to_address"   AS addr,  + "value_wei"            AS delta FROM value_transfers
    UNION ALL
    SELECT "from_address" AS addr,  - "value_wei"            AS delta FROM value_transfers
),

gas_costs AS (                     -- 2) gas spent by senders  (negative)
    SELECT
        "from_address"             AS addr,
        - CAST("gas_price" * "receipt_gas_used" AS NUMBER)   AS delta
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_status" = 1
      AND "receipt_gas_used" IS NOT NULL
),

miner_fees AS (                    -- 3) gas fees paid to block miners (positive)
    SELECT
        b."miner"                  AS addr,
        CAST(t."gas_price" * t."receipt_gas_used" AS NUMBER) AS delta
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t
    JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS      b
         ON t."block_number" = b."number"
    WHERE t."receipt_status" = 1
      AND t."receipt_gas_used" IS NOT NULL
),

all_deltas AS (                    -- combine every balance-affecting delta
    SELECT * FROM transfer_deltas
    UNION ALL
    SELECT * FROM gas_costs
    UNION ALL
    SELECT * FROM miner_fees
),

balances AS (                      -- net balance per address
    SELECT
        addr,
        SUM(delta) AS net_balance_wei
    FROM all_deltas
    WHERE addr IS NOT NULL
      AND addr <> ''
      AND addr <> '0x0000000000000000000000000000000000000000'
    GROUP BY addr
),

top10 AS (                         -- top-10 richest addresses
    SELECT net_balance_wei
    FROM balances
    ORDER BY net_balance_wei DESC NULLS LAST
    LIMIT 10
)

SELECT
    ROUND(AVG(net_balance_wei / 1e15), 2)  AS avg_balance_quadrillions
FROM top10;