WITH
/* ---------------------------------------------------------
-- 1.  Detect transactions that have ≥1 repeated output value
--     (outputs_total  > distinct_vals)
----------------------------------------------------------*/
outputs_dup AS (
    SELECT
        "transaction_hash"          AS tx_hash,
        COUNT(*)                    AS outputs_total,
        COUNT(DISTINCT TO_NUMBER("value")) AS distinct_vals
    FROM  CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    --  Only outputs from July-2023 onward
    WHERE "block_timestamp" >= 1688169600000000   -- 2023-07-01 00:00:00 UTC (µs)
    GROUP BY "transaction_hash"
),

/* ---------------------------------------------------------
-- 2.  Base set of non-coinbase transactions (≥ July 2023)
----------------------------------------------------------*/
tx_base AS (
    SELECT
        "hash"                                      AS tx_hash,
        "block_timestamp",
        DATE_TRUNC('month',
                   TO_TIMESTAMP("block_timestamp"/1e6))  AS month,
        TO_NUMBER("input_value")                    AS input_value,
        TO_NUMBER("output_value")                   AS output_value,
        "input_count",
        "output_count"
    FROM  CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    WHERE "block_timestamp" >= 1688169600000000          -- 2023-07-01
      AND COALESCE("is_coinbase", FALSE) = FALSE         -- exclude coinbase txs
),

/* ---------------------------------------------------------
-- 3.  Enrich with output-pattern info & assign CoinJoin flag
----------------------------------------------------------*/
tx_enriched AS (
    SELECT
        t.*,
        o.outputs_total,
        o.distinct_vals,
        /* CoinJoin definition
           • >2 outputs
           • total output value ≤ total input value
           • ≥1 duplicate-value output                    */
        CASE
            WHEN o.outputs_total > 2
             AND t.output_value <= t.input_value
             AND o.outputs_total > o.distinct_vals
            THEN 1 ELSE 0
        END                                            AS is_coinjoin
    FROM tx_base t
    LEFT JOIN outputs_dup o
           ON t.tx_hash = o.tx_hash
)

/* ---------------------------------------------------------
-- 4.  Monthly percentages for
--     (a) CoinJoin transactions
--     (b) UTXOs (inputs) in CoinJoins
--     (c) Volume (input value) in CoinJoins
----------------------------------------------------------*/
SELECT
    month,
    ROUND(100.0 * SUM(is_coinjoin) /
                 COUNT(*)                       , 4) AS pct_coinjoin_transactions,
    ROUND(100.0 * SUM(CASE WHEN is_coinjoin = 1
                           THEN "input_count"
                           ELSE 0 END) /
                 SUM("input_count")             , 4) AS pct_utxos_in_coinjoins,
    ROUND(100.0 * SUM(CASE WHEN is_coinjoin = 1
                           THEN input_value
                           ELSE 0 END) /
                 SUM(input_value)               , 4) AS pct_volume_in_coinjoins
FROM   tx_enriched
GROUP  BY month
ORDER  BY month
;