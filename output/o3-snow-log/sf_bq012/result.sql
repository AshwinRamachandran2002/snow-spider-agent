WITH eth_in AS (                 -- incoming ETH (successful “normal” calls)
    SELECT
        "to_address"                    AS addr,
        SUM("value")                    AS in_wei
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES"
    WHERE  "trace_type" = 'call'
      AND  "status"     = 1
      AND  ( "call_type" IS NULL
             OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
    GROUP  BY "to_address"
), eth_out AS (                 -- outgoing ETH
    SELECT
        "from_address"                 AS addr,
        SUM("value")                   AS out_wei
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES"
    WHERE  "trace_type" = 'call'
      AND  "status"     = 1
      AND  ( "call_type" IS NULL
             OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
    GROUP  BY "from_address"
), gas_fees AS (                -- gas fees paid by senders
    SELECT
        "from_address"                         AS addr,
        SUM("gas_price" * "receipt_gas_used")  AS gas_paid_wei
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS"
    WHERE  "receipt_gas_used" IS NOT NULL
    GROUP  BY "from_address"
), per_block_fees AS (          -- dynamic gas-fee rewards per block
    SELECT
        "block_number",
        SUM("gas_price" * "receipt_gas_used")  AS gas_fee_rewards_wei
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS"
    WHERE  "receipt_gas_used" IS NOT NULL
    GROUP  BY "block_number"
), miner_rewards AS (           -- static + dynamic miner rewards
    SELECT
        r."to_address"                         AS addr,
        SUM(r."value" +
            COALESCE(f.gas_fee_rewards_wei,0)) AS miner_reward_wei
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES"      r
    LEFT   JOIN per_block_fees                                    f
           ON f."block_number" = r."block_number"
    WHERE  r."trace_type"  = 'reward'
      AND  r."reward_type" = 'block'
    GROUP  BY r."to_address"
), all_addrs AS (              -- union of every address that appears anywhere
    SELECT addr FROM eth_in
    UNION
    SELECT addr FROM eth_out
    UNION
    SELECT addr FROM gas_fees
    UNION
    SELECT addr FROM miner_rewards
), balances AS (               -- net balance per address (in Wei)
    SELECT
        a.addr,
        COALESCE(in_wei,0)
      - COALESCE(out_wei,0)
      + COALESCE(miner_reward_wei,0)
      - COALESCE(gas_paid_wei,0)         AS balance_wei
    FROM all_addrs              a
    LEFT JOIN eth_in        USING(addr)
    LEFT JOIN eth_out       USING(addr)
    LEFT JOIN gas_fees      USING(addr)
    LEFT JOIN miner_rewards USING(addr)
    WHERE a.addr IS NOT NULL
), top10 AS (                  -- 10 largest balances
    SELECT balance_wei
    FROM   balances
    ORDER  BY balance_wei DESC NULLS LAST
    LIMIT  10
)
SELECT
    ROUND(AVG(balance_wei) / 1e15 , 2)   AS avg_balance_quadrillions
FROM   top10;