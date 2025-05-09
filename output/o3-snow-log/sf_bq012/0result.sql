WITH traces_filtered AS (                -- successful ETH transfers only
    SELECT 
        "to_address",
        "from_address",
        "value"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "trace_type" = 'call'
      AND "status" = 1
      AND ( "call_type" IS NULL 
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND "value" IS NOT NULL
      AND "value" > 0
),
incoming AS (                             -- wei received per address
    SELECT "to_address"  AS addr,
           SUM("value")  AS in_wei
    FROM traces_filtered
    GROUP BY "to_address"
),
outgoing AS (                             -- wei sent per address
    SELECT "from_address" AS addr,
           SUM("value")   AS out_wei
    FROM traces_filtered
    GROUP BY "from_address"
),
gas_fees AS (                             -- gas fees paid by senders
    SELECT "from_address"                          AS addr,
           SUM("receipt_gas_used" * "gas_price")   AS gas_fee_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_gas_used" IS NOT NULL
      AND "gas_price"        IS NOT NULL
    GROUP BY "from_address"
),
tx_block_fees AS (                        -- total gas fees per block
    SELECT "block_number",
           SUM("receipt_gas_used" * "gas_price")   AS block_gas_fee_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_gas_used" IS NOT NULL
      AND "gas_price"        IS NOT NULL
    GROUP BY "block_number"
),
miner_rewards AS (                        -- miner reward = sum of tx gas fees
    SELECT b."miner"        AS addr,
           SUM(t.block_gas_fee_wei)  AS miner_reward_wei
    FROM tx_block_fees t
    JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS b
      ON t."block_number" = b."number"
    GROUP BY b."miner"
),
addresses AS (                            -- union of all relevant addresses
    SELECT addr FROM incoming
    UNION
    SELECT addr FROM outgoing
    UNION
    SELECT addr FROM gas_fees
    UNION
    SELECT addr FROM miner_rewards
),
balances AS (                             -- net balance per address
    SELECT 
        a.addr                                             AS address,
        COALESCE(i.in_wei,0) 
        + COALESCE(m.miner_reward_wei,0)
        - COALESCE(o.out_wei,0)
        - COALESCE(g.gas_fee_wei,0)                        AS net_balance_wei
    FROM addresses            a
    LEFT JOIN incoming        i ON a.addr = i.addr
    LEFT JOIN outgoing        o ON a.addr = o.addr
    LEFT JOIN gas_fees        g ON a.addr = g.addr
    LEFT JOIN miner_rewards   m ON a.addr = m.addr
    WHERE a.addr IS NOT NULL
      AND a.addr <> '0x0000000000000000000000000000000000000000'
),
top10 AS (                               -- richest 10 addresses
    SELECT address, net_balance_wei
    FROM balances
    ORDER BY net_balance_wei DESC NULLS LAST
    LIMIT 10
)
SELECT 
    ROUND( AVG(net_balance_wei) / 1e15 , 2)  AS avg_balance_quadrillion_wei
FROM top10;