WITH inc AS (                                   -- incoming Wei from successful plain calls
    SELECT
        "to_address"          AS "addr",
        SUM("value")          AS "inc_wei"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "status"      = 1
      AND  "trace_type"  = 'call'
      AND  ("call_type" IS NULL OR "call_type" = 'call')
      AND  "value"       > 0
    GROUP BY "to_address"
), out AS (                                     -- outgoing Wei from the same calls
    SELECT
        "from_address"        AS "addr",
        SUM("value")          AS "out_wei"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE  "status"      = 1
      AND  "trace_type"  = 'call'
      AND  ("call_type" IS NULL OR "call_type" = 'call')
      AND  "value"       > 0
    GROUP BY "from_address"
), net_tx AS (                                  -- net transfers
    SELECT
        COALESCE(inc."addr", out."addr")                    AS "addr",
        COALESCE(inc."inc_wei", 0) -
        COALESCE(out."out_wei", 0)                          AS "net_transfer_wei"
    FROM inc
    FULL JOIN out
           ON inc."addr" = out."addr"
), miner_rewards AS (                           -- gas-fee rewards to block miners
    SELECT
        B."miner"                                 AS "addr",
        SUM(T."gas_price" * T."receipt_gas_used") AS "miner_reward_wei"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS        B
    JOIN   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS  T
           ON B."hash" = T."block_hash"
    WHERE  T."receipt_status" = 1
    GROUP BY B."miner"
), gas_fees AS (                                -- gas fees paid by senders
    SELECT
        "from_address"                           AS "addr",
        SUM("gas_price" * "receipt_gas_used")    AS "gas_fee_wei"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE  "receipt_status" = 1
    GROUP BY "from_address"
), balances AS (                                -- combine all components
    SELECT
        COALESCE(net_tx."addr",
                 miner_rewards."addr",
                 gas_fees."addr")                       AS "addr",
        COALESCE(net_tx."net_transfer_wei",     0) +
        COALESCE(miner_rewards."miner_reward_wei", 0) -
        COALESCE(gas_fees."gas_fee_wei",        0)      AS "final_balance_wei"
    FROM net_tx
    FULL JOIN miner_rewards
           ON net_tx."addr" = miner_rewards."addr"
    FULL JOIN gas_fees
           ON COALESCE(net_tx."addr", miner_rewards."addr") = gas_fees."addr"
    WHERE COALESCE(net_tx."addr",
                   miner_rewards."addr",
                   gas_fees."addr") IS NOT NULL
      AND COALESCE(net_tx."addr",
                   miner_rewards."addr",
                   gas_fees."addr") NOT ILIKE '0x0000000000000000000000000000000000000000'
), top10 AS (                                   -- top-10 richest addresses
    SELECT "addr", "final_balance_wei"
    FROM   balances
    ORDER BY "final_balance_wei" DESC NULLS LAST
    LIMIT  10
)
SELECT
    ROUND(AVG("final_balance_wei") / 1e15, 2)   AS "average_balance_quadrillions"
FROM top10;