WITH successful_calls AS (    -- all value-moving, successful CALL traces, excluding delegate/static/etc.
    SELECT
        "from_address",
        "to_address",
        "value"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "trace_type" = 'call'
      AND "status"       = 1
      AND "value"       <> 0
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
),
incoming AS (                 -- wei received via CALL traces
    SELECT "to_address"   AS address,
           SUM("value")   AS in_wei
    FROM successful_calls
    GROUP BY "to_address"
),
outgoing AS (                 -- wei sent via CALL traces
    SELECT "from_address" AS address,
           SUM("value")   AS out_wei
    FROM successful_calls
    GROUP BY "from_address"
),
gas_fee_sender AS (           -- gas fees paid by transaction senders
    SELECT
        "from_address"                      AS address,
        SUM("gas_price" * "receipt_gas_used") AS gas_fee_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_gas_used" IS NOT NULL
    GROUP BY "from_address"
),
gas_fee_miner AS (            -- total gas fees earned by block miners
    SELECT
        b."miner"                           AS address,
        SUM(t."gas_price" * t."receipt_gas_used") AS miner_fee_wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS t
    JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS       b
      ON t."block_number" = b."number"
    WHERE t."receipt_gas_used" IS NOT NULL
    GROUP BY b."miner"
),
combined AS (                 -- merge all partial balances
    SELECT
        COALESCE(i.address, o.address, g.address, m.address)              AS address,
        COALESCE(i.in_wei,        0) AS in_wei,
        COALESCE(o.out_wei,       0) AS out_wei,
        COALESCE(g.gas_fee_wei,   0) AS gas_fee_wei,
        COALESCE(m.miner_fee_wei, 0) AS miner_fee_wei
    FROM incoming          i
    FULL JOIN outgoing     o ON i.address = o.address
    FULL JOIN gas_fee_sender g ON COALESCE(i.address, o.address) = g.address
    FULL JOIN gas_fee_miner  m ON COALESCE(i.address, o.address, g.address) = m.address
),
net_balance AS (              -- net balance per address
    SELECT
        address,
        (in_wei + miner_fee_wei) - (out_wei + gas_fee_wei) AS net_wei
    FROM combined
    WHERE address IS NOT NULL
      AND LOWER(address) <> '0x0000000000000000000000000000000000000000'
),
top10 AS (                     -- richest 10 addresses
    SELECT net_wei
    FROM net_balance
    ORDER BY net_wei DESC NULLS LAST
    LIMIT 10
)
SELECT
    ROUND(AVG(net_wei) / 1e15, 2) AS "avg_balance_quadrillion"
FROM top10;