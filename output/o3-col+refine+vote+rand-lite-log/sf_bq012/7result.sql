WITH
/*----------------------------------------------------------
1.  ETH transfers coming **into** an address (successful traces only)
----------------------------------------------------------*/
traces_in AS (
    SELECT
        "to_address"                           AS address,
        SUM("value")                           AS incoming_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES"
    WHERE "status" = 1                                             -- successful
      AND "to_address" IS NOT NULL
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
    GROUP BY "to_address"
),

/*----------------------------------------------------------
2.  ETH transfers **out of** an address (successful traces only)
----------------------------------------------------------*/
traces_out AS (
    SELECT
        "from_address"                         AS address,
        SUM("value")                           AS outgoing_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES"
    WHERE "status" = 1
      AND "from_address" IS NOT NULL
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
    GROUP BY "from_address"
),

/*----------------------------------------------------------
3.  Gas-fee paid by every sender per transaction
----------------------------------------------------------*/
tx_fees AS (
    SELECT
        "hash"                                 AS tx_hash,
        "from_address"                         AS address,
        ("receipt_gas_used" * "gas_price")     AS gas_fee_wei,
        "block_hash"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS"
    WHERE "receipt_status" = 1                                    -- successful tx
      AND "receipt_gas_used" IS NOT NULL
      AND "gas_price"        IS NOT NULL
      AND "from_address"     IS NOT NULL
),

/*----------------------------------------------------------
4.  Gas-fees aggregated per miner (block producer)
----------------------------------------------------------*/
miner_rewards AS (
    SELECT
        b."miner"                              AS address,
        SUM(f.gas_fee_wei)                     AS miner_reward_wei
    FROM tx_fees f
    JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."BLOCKS" b
          ON b."hash" = f."block_hash"
    WHERE b."miner" IS NOT NULL
    GROUP BY b."miner"
),

/*----------------------------------------------------------
5.  Gas-fees aggregated per sender (to be deducted)
----------------------------------------------------------*/
sender_fees AS (
    SELECT
        address,
        SUM(gas_fee_wei)                       AS sender_fee_wei
    FROM tx_fees
    GROUP BY address
),

/*----------------------------------------------------------
6.  Combine all monetary movements to get net balance per address
----------------------------------------------------------*/
all_addresses AS (   -- collect every address that appears anywhere
    SELECT address FROM traces_in
    UNION
    SELECT address FROM traces_out
    UNION
    SELECT address FROM miner_rewards
    UNION
    SELECT address FROM sender_fees
),

balances AS (
    SELECT
        a.address,
        COALESCE(ti.incoming_wei,     0)   -- incoming transfers
      - COALESCE(to1.outgoing_wei,    0)   -- outgoing transfers
      + COALESCE(mr.miner_reward_wei,0)   -- miner gas-fee rewards
      - COALESCE(sf.sender_fee_wei,  0)   -- sender gas-fee cost
        AS net_balance_wei
    FROM all_addresses a
    LEFT JOIN traces_in      ti ON ti.address  = a.address
    LEFT JOIN traces_out     to1 ON to1.address = a.address
    LEFT JOIN miner_rewards  mr ON mr.address  = a.address
    LEFT JOIN sender_fees    sf ON sf.address  = a.address
),

/*----------------------------------------------------------
7.  Pick top-10 addresses by net balance
----------------------------------------------------------*/
top10 AS (
    SELECT address, net_balance_wei
    FROM   balances
    WHERE  address IS NOT NULL
       AND address <> '0x0000000000000000000000000000000000000000'
    ORDER  BY net_balance_wei DESC NULLS LAST
    LIMIT  10
)

/*----------------------------------------------------------
8.  Average of their balances expressed in quadrillions (1e15)
----------------------------------------------------------*/
SELECT
    ROUND( AVG(net_balance_wei) / 1e15 , 2)          AS "avg_balance_quadrillions"
FROM top10;