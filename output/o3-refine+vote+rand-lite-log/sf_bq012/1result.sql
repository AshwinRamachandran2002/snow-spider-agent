WITH trace_transfers AS (   -- +incoming  / -outgoing value moves
    /* incoming */
    SELECT
        "to_address"      AS address,
        SUM("value")      AS delta
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
    WHERE "status" = 1
      AND ("call_type" IS NULL
           OR UPPER("call_type") NOT IN ('DELEGATECALL','CALLCODE','STATICCALL'))
      AND "to_address" IS NOT NULL
      AND "to_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "to_address"

    UNION ALL                /* outgoing */
    SELECT
        "from_address"       AS address,
        -SUM("value")        AS delta
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRACES"
    WHERE "status" = 1
      AND ("call_type" IS NULL
           OR UPPER("call_type") NOT IN ('DELEGATECALL','CALLCODE','STATICCALL'))
      AND "from_address" IS NOT NULL
      AND "from_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "from_address"
),

gas_fees AS (               -- ‑gas for senders  / +gas for miners
    /* sender gas‑fee deduction */
    SELECT
        "from_address"                             AS address,
        -SUM("gas_price" * "receipt_gas_used")     AS delta
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRANSACTIONS"
    WHERE "receipt_status" = 1
      AND "from_address" IS NOT NULL
      AND "from_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "from_address"

    UNION ALL            /* miner gas‑fee reward */
    SELECT
        b."miner"                                AS address,
        SUM(t."gas_price" * t."receipt_gas_used") AS delta
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TRANSACTIONS" t
    JOIN "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."BLOCKS" b
      ON t."block_number" = b."number"
    WHERE t."receipt_status" = 1
      AND b."miner" IS NOT NULL
      AND b."miner" <> '0x0000000000000000000000000000000000000000'
    GROUP BY b."miner"
),

all_deltas AS (             -- collect every positive / negative contribution
    SELECT * FROM trace_transfers
    UNION ALL
    SELECT * FROM gas_fees
),

balances AS (               -- net balance per address
    SELECT
        address,
        SUM(delta) AS balance_wei
    FROM all_deltas
    GROUP BY address
    HAVING SUM(delta) IS NOT NULL
),

top10 AS (                  -- richest 10 addresses
    SELECT
        address,
        balance_wei
    FROM balances
    ORDER BY balance_wei DESC NULLS LAST
    LIMIT 10
)

SELECT
    ROUND(AVG(balance_wei) / 1e15, 2) AS "average_balance_quadrillions"
FROM top10;