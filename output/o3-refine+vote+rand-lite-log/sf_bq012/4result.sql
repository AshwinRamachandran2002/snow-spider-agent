WITH trace_calls AS (           -- successful value transfers coming from traces
    SELECT
        "from_address",
        "to_address",
        CAST("value" AS DECIMAL(38,0))                                 AS "value"
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRACES"
    WHERE "status" = 1
      AND "trace_type" = 'call'
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
      AND "value" IS NOT NULL
),

/* + incoming – outgoing value transferred */
transfer_contributions AS (
    SELECT  "to_address"   AS address,
            SUM("value")   AS amount
    FROM trace_calls
    WHERE "to_address" IS NOT NULL
    GROUP BY "to_address"

    UNION ALL

    SELECT  "from_address" AS address,
           -SUM("value")   AS amount
    FROM trace_calls
    WHERE "from_address" IS NOT NULL
    GROUP BY "from_address"
),

/* gas fee (gas_used * gas_price) calculated per transaction */
tx_fees AS (
    SELECT
        "hash"                         AS tx_hash,
        "from_address",
        "block_hash",
        CAST(COALESCE("receipt_gas_used",0) AS DECIMAL(38,0))
        * CAST(COALESCE("gas_price",0)       AS DECIMAL(38,0))           AS fee
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TRANSACTIONS"
    WHERE "from_address" IS NOT NULL
      AND ( "receipt_status" = 1 OR "receipt_status" IS NULL )           -- successful
),

/* − fee for every sender */
sender_fee_contributions AS (
    SELECT  "from_address" AS address,
           -SUM(fee)       AS amount
    FROM tx_fees
    GROUP BY "from_address"
),

/* + total fees of a block credited to the miner */
miner_fee_contributions AS (
    SELECT  b."miner"      AS address,
            SUM(f.fee)     AS amount
    FROM tx_fees f
    JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."BLOCKS" b
          ON b."hash" = f."block_hash"
    WHERE b."miner" IS NOT NULL
    GROUP BY b."miner"
),

/* gather every monetary movement */
all_contributions AS (
    SELECT * FROM transfer_contributions
    UNION ALL
    SELECT * FROM sender_fee_contributions
    UNION ALL
    SELECT * FROM miner_fee_contributions
),

/* final net balance per address */
balances AS (
    SELECT  address,
            SUM(amount) AS balance
    FROM all_contributions
    WHERE address IS NOT NULL
      AND address <> '0x0000000000000000000000000000000000000000'
    GROUP BY address
),

/* ten richest addresses */
top10 AS (
    SELECT balance
    FROM balances
    ORDER BY balance DESC NULLS LAST
    LIMIT 10
)

SELECT
    ROUND( AVG(balance) / 1e15 , 2)    AS "average_balance_quadrillion"
FROM top10;