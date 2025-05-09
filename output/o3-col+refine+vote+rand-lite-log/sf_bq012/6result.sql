WITH call_in AS (   -- incoming Ether from plain successful CALL traces
    SELECT
        "to_address"              AS addr,
        SUM("value")              AS in_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status"      = 1
      AND "trace_type"  = 'call'
      AND "call_type"   = 'call'          -- exclude delegatecall / staticcall / callcode
      AND "value"       > 0
      AND "to_address"  IS NOT NULL
    GROUP BY "to_address"
),
call_out AS (        -- outgoing Ether from the same kind of traces
    SELECT
        "from_address"            AS addr,
        SUM("value")              AS out_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status"      = 1
      AND "trace_type"  = 'call'
      AND "call_type"   = 'call'
      AND "value"       > 0
      AND "from_address" IS NOT NULL
    GROUP BY "from_address"
),
net_bal AS (         -- net (incoming - outgoing) per address
    SELECT
        COALESCE(ci.addr, co.addr)                                   AS address,
        COALESCE(ci.in_wei, 0) - COALESCE(co.out_wei, 0)             AS net_wei
    FROM call_in ci
    FULL OUTER JOIN call_out co
        ON ci.addr = co.addr
),
rewards AS (         -- miner & uncle rewards credited to addresses
    SELECT
        "to_address"            AS address,
        SUM("value")            AS reward_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "trace_type" = 'reward'
    GROUP BY "to_address"
),
gas_fees AS (        -- gas fees paid (gas_price * gas_used) by transaction senders
    SELECT
        "from_address"                              AS address,
        SUM("gas_price" * "receipt_gas_used")       AS gas_fee_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_gas_used" IS NOT NULL
    GROUP BY "from_address"
),
adjusted AS (        -- adjusted net balance = net_wei + rewards - gas_fees
    SELECT
        nb.address,
        nb.net_wei
        + COALESCE(r.reward_wei, 0)
        - COALESCE(g.gas_fee_wei, 0)                AS adjusted_net_wei
    FROM net_bal nb
    LEFT JOIN rewards  r ON nb.address = r.address
    LEFT JOIN gas_fees g ON nb.address = g.address
    WHERE nb.address ILIKE '0x%'
      AND nb.address NOT ILIKE '0x0000000000000000000000000000000000000000'
),
top10 AS (           -- the 10 richest addresses by adjusted net balance
    SELECT adjusted_net_wei
    FROM adjusted
    ORDER BY adjusted_net_wei DESC NULLS LAST
    LIMIT 10
)
SELECT
    ROUND( AVG(adjusted_net_wei) / 1e15 , 2)  AS avg_balance_quadrillion_wei
FROM top10;