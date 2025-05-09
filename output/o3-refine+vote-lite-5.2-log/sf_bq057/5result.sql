WITH tx AS (   -- Bitcoin transactions in 2021
    SELECT
        "hash"                                           AS txhash,
        MONTH(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS month,
        "input_count"                                    AS input_cnt,
        "output_count"                                   AS output_cnt,
        CAST("input_value"  AS FLOAT)                    AS input_val,
        CAST("output_value" AS FLOAT)                    AS output_val,
        "outputs"                                        AS outputs
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE YEAR(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) = 2021
),
out_values AS (   -- every output’s value per tx
    SELECT
        t.txhash,
        f.value:"value"::FLOAT  AS out_val
    FROM tx t,
         LATERAL FLATTEN(input => t.outputs) f
),
dup_stats AS (   -- duplicates of equal‑value outputs
    SELECT
        txhash,
        COUNT(*)                AS outs,
        COUNT(DISTINCT out_val) AS distinct_out_vals
    FROM out_values
    GROUP BY txhash
),
tx_cj AS (   -- flag CoinJoin transactions
    SELECT
        t.month,
        t.txhash,
        t.input_cnt,
        t.output_cnt,
        t.input_val,
        t.output_val,
        CASE
            WHEN t.output_cnt > 2
             AND t.output_val <= t.input_val
             AND ds.outs - ds.distinct_out_vals >= 1   -- ≥1 duplicate value
            THEN 1 ELSE 0
        END AS is_cj
    FROM tx t
    JOIN dup_stats ds
      ON t.txhash = ds.txhash
),
monthly AS (   -- month‑level aggregates
    SELECT
        month,
        SUM(is_cj)                                           AS cj_tx,
        COUNT(*)                                             AS total_tx,
        SUM(CASE WHEN is_cj = 1 THEN input_cnt  END)         AS cj_inputs,
        SUM(input_cnt)                                       AS tot_inputs,
        SUM(CASE WHEN is_cj = 1 THEN output_cnt END)         AS cj_outputs,
        SUM(output_cnt)                                      AS tot_outputs,
        SUM(CASE WHEN is_cj = 1 THEN output_val END)         AS cj_volume,
        SUM(output_val)                                      AS tot_volume
    FROM tx_cj
    GROUP BY month
),
metrics AS (   -- percentages per month
    SELECT
        month,
        100.0 * cj_tx     / NULLIF(total_tx   ,0)                               AS pct_tx,
        100.0 * ( (cj_inputs / NULLIF(tot_inputs ,0) +
                   cj_outputs/ NULLIF(tot_outputs,0) ) / 2 )                    AS pct_utxo,
        100.0 * cj_volume / NULLIF(tot_volume ,0)                               AS pct_vol
    FROM monthly
)
SELECT
    month                                            AS month_number,
    ROUND(pct_tx ,1)   AS pct_transactions_coinjoin,
    ROUND(pct_utxo,1)  AS pct_utxos_coinjoin,
    ROUND(pct_vol ,1)  AS pct_volume_coinjoin
FROM metrics
ORDER BY pct_vol DESC NULLS LAST, month
LIMIT 1;