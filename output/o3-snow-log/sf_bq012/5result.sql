WITH
/* 1. Wei sent to each address via successful value-transferring calls            */
incoming AS (
    SELECT
        "to_address"                           AS address,
        SUM(CAST("value" AS NUMBER))           AS in_wei
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "status" = 1
      AND  "trace_type" = 'call'
      AND  COALESCE("call_type",'call') NOT IN ('delegatecall','callcode','staticcall')
      AND  COALESCE(CAST("value" AS NUMBER),0) <> 0
    GROUP BY "to_address"
),

/* 2. Wei sent out from each address                                              */
outgoing AS (
    SELECT
        "from_address"                         AS address,
        SUM(CAST("value" AS NUMBER))           AS out_wei
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "status" = 1
      AND  "trace_type" = 'call'
      AND  COALESCE("call_type",'call') NOT IN ('delegatecall','callcode','staticcall')
      AND  COALESCE(CAST("value" AS NUMBER),0) <> 0
    GROUP BY "from_address"
),

/* 3. Block- / uncle-rewards paid to miners                                       */
rewards AS (
    SELECT
        "to_address"                           AS address,
        SUM(CAST("value" AS NUMBER))           AS reward_wei
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "trace_type" = 'reward'
    GROUP BY "to_address"
),

/* 4. Gas fees paid (deducted) by transaction senders                             */
sender_fees AS (
    SELECT
        "from_address"                                             AS address,
        SUM( COALESCE("receipt_gas_used",0) * COALESCE("gas_price",0) ) AS fee_wei
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    GROUP BY "from_address"
),

/* 5. Gas fees earned by miners (sum of fees per block)                           */
block_fees AS (      -- total fees per block
    SELECT
        "block_number",
        SUM( COALESCE("receipt_gas_used",0) * COALESCE("gas_price",0) ) AS total_fee
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    GROUP BY "block_number"
),
miner_fees AS (      -- attach those fees to the block’s miner
    SELECT
        b."miner"                          AS address,
        SUM(f.total_fee)                   AS miner_fee_wei
    FROM   block_fees f
    JOIN   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS b
          ON f."block_number" = b."number"
    GROUP BY b."miner"
),

/* 6. Combine every component into a single net balance per address               */
net_balances AS (
    SELECT
        COALESCE(i.address,o.address,r.address,s.address,m.address)        AS address,
        COALESCE(in_wei,0)
      + COALESCE(reward_wei,0)
      + COALESCE(miner_fee_wei,0)
      - COALESCE(out_wei,0)
      - COALESCE(fee_wei,0)                                                AS net_wei
    FROM       incoming     i
    FULL JOIN  outgoing     o  ON i.address = o.address
    FULL JOIN  rewards      r  ON COALESCE(i.address,o.address) = r.address
    FULL JOIN  sender_fees  s  ON COALESCE(i.address,o.address,r.address) = s.address
    FULL JOIN  miner_fees   m  ON COALESCE(i.address,o.address,r.address,s.address) = m.address
    WHERE  COALESCE(i.address,o.address,r.address,s.address,m.address) IS NOT NULL
      AND  LOWER(COALESCE(i.address,o.address,r.address,s.address,m.address))
           <> '0x0000000000000000000000000000000000000000'
)

/* 7. Average (in quadrillions) of the top-10 net balances                        */
SELECT
    ROUND( AVG(net_wei) / 1e15 , 2)  AS average_top10_balance_quadrillions
FROM (
    SELECT net_wei
    FROM   net_balances
    ORDER  BY net_wei DESC NULLS LAST
    LIMIT  10
);