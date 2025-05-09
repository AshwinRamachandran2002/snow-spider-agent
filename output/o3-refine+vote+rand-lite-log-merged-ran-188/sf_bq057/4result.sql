WITH tx_2021 AS (   -- all non‑coinbase Bitcoin txs in 2021
    SELECT
        t."hash"                                      AS tx_hash,
        t."input_count"                               AS input_cnt,
        t."output_count"                              AS output_cnt,
        t."input_value"                               AS input_val,
        t."output_value"                              AS output_val,
        CAST(TO_CHAR(TO_TIMESTAMP(t."block_timestamp"/1e6),'MM') AS INT) AS month
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS t
    WHERE t."is_coinbase" = FALSE
      AND TO_CHAR(TO_TIMESTAMP(t."block_timestamp"/1e6),'YYYY') = '2021'
),
outs AS (           -- output stats per tx
    SELECT
        o."transaction_hash"         AS tx_hash,
        COUNT(*)                     AS outputs_total,
        COUNT(DISTINCT o."value")    AS distinct_vals
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS o
    WHERE TO_CHAR(TO_TIMESTAMP(o."block_timestamp"/1e6),'YYYY') = '2021'
    GROUP BY o."transaction_hash"
),
tagged AS (         -- mark CoinJoin txs
    SELECT
        tx.*,
        CASE
            WHEN o.outputs_total > 2
             AND o.distinct_vals < o.outputs_total     -- repeated equal‑value outputs
             AND tx.output_val <= tx.input_val
            THEN 1 ELSE 0
        END AS is_coinjoin
    FROM tx_2021 tx
    JOIN outs o ON o.tx_hash = tx.tx_hash
),
stats AS (          -- monthly aggregates
    SELECT
        month,
        COUNT(*)                                             AS total_tx,
        COALESCE(SUM(input_cnt),0)                           AS total_inputs,
        COALESCE(SUM(output_cnt),0)                          AS total_outputs,
        COALESCE(SUM(output_val),0)                          AS total_volume,
        SUM(CASE WHEN is_coinjoin=1 THEN 1          ELSE 0 END) AS cj_tx,
        SUM(CASE WHEN is_coinjoin=1 THEN input_cnt  ELSE 0 END) AS cj_inputs,
        SUM(CASE WHEN is_coinjoin=1 THEN output_cnt ELSE 0 END) AS cj_outputs,
        SUM(CASE WHEN is_coinjoin=1 THEN output_val ELSE 0 END) AS cj_volume
    FROM tagged
    GROUP BY month
),
pct AS (           -- monthly percentages
    SELECT
        month,
        ROUND(cj_tx     *100.0 / NULLIF(total_tx    ,0),1)                                 AS pct_tx,
        ROUND(((cj_inputs*1.0/NULLIF(total_inputs ,0)) +
               (cj_outputs*1.0/NULLIF(total_outputs,0))) * 50 ,1)                          AS pct_utxo,
        ROUND(cj_volume *100.0 / NULLIF(total_volume,0),1)                                 AS pct_vol
    FROM stats
)
SELECT
    month              AS month_of_2021,
    pct_tx             AS percent_tx_coinjoin,
    pct_utxo           AS percent_utxo_coinjoin,
    pct_vol            AS percent_volume_coinjoin
FROM pct
ORDER BY pct_vol DESC NULLS LAST, month
LIMIT 1;