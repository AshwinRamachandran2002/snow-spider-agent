WITH day_txs AS (   -- successful external transactions on 2016‑10‑14 (UTC)
    SELECT
        "hash"                 AS "tx_hash",
        "block_number",
        "from_address",
        "to_address",
        "value",
        COALESCE("gas_price",0)        AS "gas_price",
        COALESCE("receipt_gas_used",0) AS "gas_used"
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRANSACTIONS
    WHERE "block_timestamp" BETWEEN 1476403200000000    -- 2016‑10‑14 00:00:00 UTC
                               AND 1476489599999999    -- 2016‑10‑14 23:59:59.999999 UTC
      AND ( "receipt_status" = 1 OR "receipt_status" IS NULL )
),
tx_with_fee AS (               -- sender‑side gas fee in Wei
    SELECT *,
           ("gas_price" * "gas_used") AS "gas_fee"
    FROM   day_txs
),
block_miners AS (              -- miner address for every block that day
    SELECT
        "number"  AS "block_number",
        "miner"   AS "miner_address"
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC.BLOCKS
    WHERE "timestamp" BETWEEN 1476403200000000 AND 1476489599999999
),
tx_enriched AS (               -- attach miner to each tx
    SELECT
        t.*,
        m."miner_address"
    FROM   tx_with_fee t
    LEFT  JOIN block_miners m
           ON t."block_number" = m."block_number"
),
reward_traces AS (             -- native block rewards credited to miners
    SELECT
        "to_address" AS "miner_address",
        "value"      AS "reward_value"
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRACES
    WHERE "block_timestamp" BETWEEN 1476403200000000 AND 1476489599999999
      AND "trace_type"  = 'reward'
      AND "reward_type" = 'block'
),
movements AS (                 -- +ve credit, −ve debit
    /* funds received */
    SELECT "to_address" AS "address",
           SUM("value") AS "amt"
    FROM   tx_enriched
    WHERE  "to_address" IS NOT NULL
    GROUP  BY "to_address"

    UNION ALL

    /* funds & gas fee sent */
    SELECT "from_address" AS "address",
           SUM(-"value" - "gas_fee") AS "amt"
    FROM   tx_enriched
    WHERE  "from_address" IS NOT NULL
    GROUP  BY "from_address"

    UNION ALL

    /* gas fee credited to miner */
    SELECT "miner_address" AS "address",
           SUM("gas_fee")  AS "amt"
    FROM   tx_enriched
    WHERE  "miner_address" IS NOT NULL
    GROUP  BY "miner_address"

    UNION ALL

    /* protocol block reward credited to miner */
    SELECT "miner_address" AS "address",
           SUM("reward_value") AS "amt"
    FROM   reward_traces
    GROUP  BY "miner_address"
),
net_change AS (                 -- daily net balance change per address
    SELECT "address",
           SUM("amt") AS "net_bal_change"
    FROM   movements
    GROUP  BY "address"
)
SELECT
    MAX("net_bal_change") AS "max_net_change",
    MIN("net_bal_change") AS "min_net_change"
FROM net_change;