WITH trace_transfers AS (          -- value movements coming from traces
    /* incoming value */
    SELECT
        "to_address"        AS address,
        SUM("value")        AS delta
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status" = 1
      AND "value" IS NOT NULL
      AND ("trace_type" IN ('call','create','suicide','reward'))
      AND ( "call_type" IS NULL
            OR UPPER("call_type") NOT IN ('DELEGATECALL','CALLCODE','STATICCALL') )
    GROUP BY address

    UNION ALL                -- outgoing value
    SELECT
        "from_address"       AS address,
        -SUM("value")        AS delta
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status" = 1
      AND "value" IS NOT NULL
      AND ("trace_type" IN ('call','create','suicide'))         -- reward‑traces have no sender
      AND ( "call_type" IS NULL
            OR UPPER("call_type") NOT IN ('DELEGATECALL','CALLCODE','STATICCALL') )
    GROUP BY address
),

gas_fees AS (                 -- gas fees paid by transaction senders
    SELECT
        "from_address"                                    AS address,
        -SUM("gas_price" * "receipt_gas_used")            AS delta
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_gas_used" IS NOT NULL
    GROUP BY address
),

fees_per_block AS (           -- total gas fees in every block
    SELECT
        "block_number",
        SUM("gas_price" * "receipt_gas_used")             AS fees
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "receipt_gas_used" IS NOT NULL
    GROUP BY "block_number"
),

miner_rewards AS (            -- gas fees credited to miners
    SELECT
        b."miner"                                       AS address,
        SUM(f.fees)                                     AS delta
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS  b
    JOIN fees_per_block                                 f
      ON b."number" = f."block_number"
    GROUP BY address
),

all_flows AS (                -- union of every balance‑changing flow
    SELECT * FROM trace_transfers
    UNION ALL
    SELECT * FROM gas_fees
    UNION ALL
    SELECT * FROM miner_rewards
),

address_balance AS (          -- net balance per address
    SELECT
        address,
        SUM(delta) AS net_balance
    FROM all_flows
    WHERE address IS NOT NULL
      AND LOWER(address) <> '0x0000000000000000000000000000000000000000'
    GROUP BY address
),

top10 AS (                     -- ten richest addresses
    SELECT
        net_balance
    FROM address_balance
    ORDER BY net_balance DESC NULLS LAST
    LIMIT 10
)

/* average balance in quadrillions (10^15), rounded to two decimals */
SELECT
    ROUND(AVG(net_balance / 1e15), 2) AS "AVG_BALANCE_QUADRILLIONS"
FROM top10;