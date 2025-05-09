WITH date_blocks AS (   -- all blocks on 14-Oct-2016 (UTC)
    SELECT  "number"     AS block_number,
            "miner"
    FROM    CRYPTO.CRYPTO_ETHEREUM_CLASSIC.BLOCKS
    WHERE   "timestamp" >= 1476403200000000   -- 2016-10-14 00:00:00 UTC
      AND   "timestamp" <  1476489600000000   -- 2016-10-15 00:00:00 UTC
),
tx AS (                  -- successful, external transactions in those blocks
    SELECT  t.*,
            (t."receipt_gas_used" * t."gas_price") AS fee
    FROM    CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRANSACTIONS t
    JOIN    date_blocks b
           ON b.block_number = t."block_number"
    WHERE   (t."receipt_status" = 1 OR t."receipt_status" IS NULL)   -- success
),
contributions AS (       -- balance deltas for every address & fee for miners
    /* sender: pays value and fee */
    SELECT  "from_address"          AS addr,
           -("value" + fee)         AS delta
    FROM    tx
    WHERE   "from_address" IS NOT NULL

    UNION ALL
    /* receiver: gets value */
    SELECT  "to_address"            AS addr,
            "value"                 AS delta
    FROM    tx
    WHERE   "to_address" IS NOT NULL

    UNION ALL
    /* miner: receives the fee */
    SELECT  b."miner"               AS addr,
            fee                     AS delta
    FROM    tx
    JOIN    date_blocks b
           ON b.block_number = tx."block_number"
    WHERE   b."miner" IS NOT NULL
),
net_changes AS (         -- net balance change per address
    SELECT  addr,
            SUM(delta)  AS net_change
    FROM    contributions
    GROUP BY addr
)
SELECT  MAX(net_change) AS "max_net_balance_change",
        MIN(net_change) AS "min_net_balance_change"
FROM    net_changes;