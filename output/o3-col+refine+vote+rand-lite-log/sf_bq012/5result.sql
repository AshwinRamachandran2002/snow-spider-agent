/* Average balance (in 10^15 Wei) of the 10 richest Ethereum addresses */
WITH
/* 1. Net ether moved via successful call–traces (exclude delegatecall/callcode/staticcall) */
trace_net AS (
    SELECT addr,
           SUM(CASE WHEN direction = 'in' THEN val ELSE -val END) AS net_wei
    FROM (
          SELECT "to_address"   AS addr,
                 "value"        AS val,
                 'in'           AS direction
          FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
          WHERE  "trace_type" = 'call'
            AND  "status"      = 1
            AND  LOWER(COALESCE("call_type",'')) NOT IN ('delegatecall','callcode','staticcall')
            AND  "to_address"  IS NOT NULL
          UNION ALL
          SELECT "from_address" AS addr,
                 "value"        AS val,
                 'out'          AS direction
          FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
          WHERE  "trace_type" = 'call'
            AND  "status"      = 1
            AND  LOWER(COALESCE("call_type",'')) NOT IN ('delegatecall','callcode','staticcall')
            AND  "from_address" IS NOT NULL
    ) t
    GROUP BY addr
),

/* 2. Native miner / uncle rewards */
miner_rewards AS (
    SELECT "to_address" AS addr,
           SUM("value") AS reward_wei
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "trace_type" = 'reward'
    GROUP BY addr
),

/* 3. Gas paid by senders (cost to deduct) */
sender_fees AS (
    SELECT "from_address" AS addr,
           SUM("gas_price" * "receipt_gas_used") AS fee_wei
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE  "receipt_gas_used" IS NOT NULL
    GROUP BY addr
),

/* 4. Gas fees earned by miners (credit) */
miner_gas_fees AS (
    SELECT  b."miner"                                           AS addr,
            SUM(t."gas_price" * t."receipt_gas_used")           AS fee_wei
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS       b
    JOIN    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t
           ON t."block_number" = b."number"
    WHERE   t."receipt_gas_used" IS NOT NULL
    GROUP BY b."miner"
),

/* 5. Combine all monetary flows */
unioned AS (
    SELECT addr, net_wei,        0            AS reward_wei, 0         AS sender_fee_wei, 0        AS miner_fee_wei FROM trace_net
    UNION ALL
    SELECT addr, 0,              reward_wei,  0,                        0                  FROM miner_rewards
    UNION ALL
    SELECT addr, 0,              0,           fee_wei,                  0                  FROM sender_fees
    UNION ALL
    SELECT addr, 0,              0,           0,                        fee_wei            FROM miner_gas_fees
),

aggregated AS (
    SELECT addr,
           SUM(net_wei)        AS net_wei,
           SUM(reward_wei)     AS reward_wei,
           SUM(sender_fee_wei) AS sender_fee_wei,
           SUM(miner_fee_wei)  AS miner_fee_wei
    FROM   unioned
    GROUP BY addr
),

balances AS (
    SELECT addr                                                   AS address,
           net_wei + reward_wei + miner_fee_wei - sender_fee_wei  AS net_balance_wei
    FROM   aggregated
)

/* 6. Top-10 richest & their average balance (in quadrillions of Wei) */
SELECT ROUND(AVG(net_balance_wei / 1e15), 2) AS average_balance_quadrillions
FROM (
      SELECT net_balance_wei
      FROM   balances
      WHERE  address IS NOT NULL
      ORDER  BY net_balance_wei DESC NULLS LAST
      LIMIT  10
);