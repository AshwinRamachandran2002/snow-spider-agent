WITH trace_bal AS (          -- net Wei from successful value-transferring traces
    WITH transfers AS (
        SELECT  "from_address" AS "address",
               - "value"       AS "amount_wei"
        FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES"
        WHERE   "status" = 1
          AND   "value"  > 0
          AND   NVL("call_type",'call') NOT IN ('delegatecall','callcode','staticcall')

        UNION ALL

        SELECT  "to_address"   AS "address",
                "value"        AS "amount_wei"
        FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES"
        WHERE   "status" = 1
          AND   "value"  > 0
          AND   NVL("call_type",'call') NOT IN ('delegatecall','callcode','staticcall')
    )
    SELECT  "address",
            SUM("amount_wei") AS "trace_wei"
    FROM    transfers
    WHERE   "address" IS NOT NULL
    GROUP BY "address"
),
miner_fees AS (              -- gas-fee rewards credited to block miners
    SELECT  b."miner"                             AS "address",
            SUM(t."gas_price" * t."receipt_gas_used") AS "miner_reward_wei"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."BLOCKS"       b
    JOIN    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS" t
           ON t."block_number" = b."number"
    WHERE   t."receipt_gas_used" IS NOT NULL
    GROUP BY b."miner"
),
sender_fees AS (             -- gas-fee costs paid by transaction senders
    SELECT  "from_address"                        AS "address",
           -SUM("gas_price" * "receipt_gas_used") AS "sender_fee_wei"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS"
    WHERE   "receipt_gas_used" IS NOT NULL
    GROUP BY "from_address"
),
all_addresses AS (           -- union of every address that has a balance component
    SELECT "address" FROM trace_bal
    UNION
    SELECT "address" FROM miner_fees
    UNION
    SELECT "address" FROM sender_fees
),
total_bal AS (               -- total net Wei per address
    SELECT  a."address",
            NVL(tb."trace_wei",0) +
            NVL(mf."miner_reward_wei",0) +
            NVL(sf."sender_fee_wei",0) AS "total_net_wei"
    FROM    all_addresses a
    LEFT JOIN trace_bal  tb ON a."address" = tb."address"
    LEFT JOIN miner_fees mf ON a."address" = mf."address"
    LEFT JOIN sender_fees sf ON a."address" = sf."address"
)
-- average (in 10^15 Wei) of the 10 richest addresses, rounded to 2 decimals
SELECT  ROUND( AVG("total_net_wei") / 1e15 , 2 ) AS "avg_balance_quadrillions"
FROM (
    SELECT "total_net_wei"
    FROM   total_bal
    ORDER  BY "total_net_wei" DESC NULLS LAST
    LIMIT  10
);