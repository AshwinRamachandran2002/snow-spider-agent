WITH
/* ----------------------------------------------------------------------
1) Successful value transfers (TRACES)
---------------------------------------------------------------------- */
trace_filtered AS (
    SELECT
        "to_address"   AS "address",
        SUM("value")   AS "wei_delta"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status" = 1
      AND "trace_type" IN ('call','create')
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
    GROUP BY "to_address"

    UNION ALL

    SELECT
        "from_address" AS "address",
        -SUM("value")  AS "wei_delta"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status" = 1
      AND "trace_type" IN ('call','create')
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
    GROUP BY "from_address"
),

/* ----------------------------------------------------------------------
2) Gas fees paid by transaction senders (TRANSACTIONS)
---------------------------------------------------------------------- */
gas_paid AS (
    SELECT
        "from_address" AS "address",
        -SUM(COALESCE("receipt_gas_used",0) * COALESCE("gas_price",0)) AS "wei_delta"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    GROUP BY "from_address"
),

/* ----------------------------------------------------------------------
3) Gas fees earned by miners (BLOCKS  ↔ TRANSACTIONS)
---------------------------------------------------------------------- */
gas_earned AS (
    SELECT
        b."miner" AS "address",
        SUM(COALESCE(t."receipt_gas_used",0) * COALESCE(t."gas_price",0)) AS "wei_delta"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS        b
    JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS  t
      ON t."block_number" = b."number"
    GROUP BY b."miner"
),

/* ----------------------------------------------------------------------
4) Combine every flow to compute net balance per address
---------------------------------------------------------------------- */
all_flows AS (
    SELECT * FROM trace_filtered
    UNION ALL
    SELECT * FROM gas_paid
    UNION ALL
    SELECT * FROM gas_earned
),
balances AS (
    SELECT
        "address",
        SUM("wei_delta") AS "net_wei"
    FROM all_flows
    WHERE "address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "address"
)

/* ----------------------------------------------------------------------
5) Average balance of the TOP‑10 richest addresses (quadrillions of Wei)
---------------------------------------------------------------------- */
SELECT
    ROUND(AVG("net_wei")/1e15, 2)  AS average_balance_quadrillions
FROM (
    SELECT "net_wei"
    FROM   balances
    ORDER  BY "net_wei" DESC NULLS LAST
    LIMIT  10
);