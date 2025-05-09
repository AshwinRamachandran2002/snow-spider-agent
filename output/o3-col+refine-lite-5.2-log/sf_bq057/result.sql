WITH tx_2021 AS (   -- all BTC txs mined in 2021
    SELECT  
        "hash",
        "input_count",
        "output_count",
        "input_value",
        "output_value",
        TO_NUMBER(TO_CHAR( TO_TIMESTAMP("block_timestamp"/1e6) , 'MM'))  AS month_num
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE TO_NUMBER(TO_CHAR( TO_TIMESTAMP("block_timestamp"/1e6) , 'YYYY')) = 2021
),                                                             -- detect “duplicate‑value” outputs
out_stats AS (
    SELECT  
        "transaction_hash" AS hash,
        COUNT(*)                     AS outputs_total,
        COUNT(DISTINCT "value")      AS distinct_values
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    GROUP BY "transaction_hash"
),                                                             -- flag candidate CoinJoin txs
flags AS (
    SELECT  
        o.hash,
        CASE WHEN o.outputs_total > 2                          -- >2 outputs
              AND o.distinct_values < o.outputs_total          -- ≥2 identical‑value outputs
        THEN 1 ELSE 0 END AS has_equal_outputs
    FROM out_stats o
),                                                             -- join flags to 2021 txs
classified AS (
    SELECT 
        t.month_num,
        t."hash",
        t."input_count",
        t."output_count",
        t."input_value",
        t."output_value",
        CASE WHEN f.has_equal_outputs = 1
                  AND t."output_count" > 2
                  AND t."output_value" <= t."input_value"
             THEN 1 ELSE 0 END                               AS is_coinjoin
    FROM tx_2021 t
    LEFT JOIN flags f ON t."hash" = f.hash
),                                                             -- monthly aggregates
monthly AS (
    SELECT
        month_num,
        COUNT(*)                                            AS total_tx,
        SUM(is_coinjoin)                                    AS cj_tx,
        SUM("input_count")                                  AS total_inputs,
        SUM(CASE WHEN is_coinjoin=1 THEN "input_count"  END) AS cj_inputs,
        SUM("output_count")                                 AS total_outputs,
        SUM(CASE WHEN is_coinjoin=1 THEN "output_count" END) AS cj_outputs,
        SUM("input_value")                                  AS total_volume,
        SUM(CASE WHEN is_coinjoin=1 THEN "input_value"  END) AS cj_volume
    FROM classified
    GROUP BY month_num
),                                                             -- convert to percentages
pct AS (
    SELECT
        month_num,
        100.0 * cj_tx      / total_tx                        AS pct_tx,
        100.0 * ( (cj_inputs/total_inputs) + (cj_outputs/total_outputs) ) / 2  AS pct_utxo,
        100.0 * cj_volume  / total_volume                   AS pct_vol
    FROM monthly
),                                                             -- month with highest volume share
best AS (
    SELECT * 
    FROM pct
    ORDER BY pct_vol DESC NULLS LAST, month_num
    LIMIT 1
)
SELECT 
    month_num                                                AS "month",
    ROUND(pct_tx  ,1)                                        AS "pct_coinjoin_transactions",
    ROUND(pct_utxo,1)                                        AS "pct_utxos_in_coinjoin",
    ROUND(pct_vol ,1)                                        AS "pct_volume_in_coinjoin"
FROM best;