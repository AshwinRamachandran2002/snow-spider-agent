WITH tx_2021 AS (                   -- all Bitcoin txs in 2021
    SELECT
        "hash",
        "block_timestamp",
        MONTH(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))      AS month_num,
        "input_value" :: FLOAT                                 AS input_val,
        "output_value":: FLOAT                                 AS output_val,
        "input_count",
        "output_count"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE YEAR(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) = 2021
),
/* transactions that contain at least two identical-value outputs
   and have more than two outputs overall                        */
cj_hashes AS (
    SELECT  o."transaction_hash"
    FROM    CRYPTO.CRYPTO_BITCOIN.OUTPUTS o
    JOIN    tx_2021 t
      ON    t."hash" = o."transaction_hash"
    GROUP BY o."transaction_hash"
    HAVING  COUNT(*) > 2                      -- >2 outputs
       AND  COUNT(DISTINCT o."value") < COUNT(*)   -- at least two equal values
),
/* classify each 2021 tx as CoinJoin or not                      */
tx_classified AS (
    SELECT
        t.*,
        CASE
            WHEN cj."transaction_hash" IS NOT NULL           -- equal-value outs
             AND t."output_count" > 2                        -- >2 outs
             AND t.output_val <= t.input_val                 -- value conservation
            THEN 1 ELSE 0
        END                                     AS is_cj
    FROM tx_2021 t
    LEFT JOIN cj_hashes cj
      ON cj."transaction_hash" = t."hash"
),
/* monthly aggregates                                             */
month_stats AS (
    SELECT
        month_num,
        COUNT(*)                                   AS total_tx,
        SUM(is_cj)                                 AS cj_tx,
        SUM("input_count")                         AS total_inputs,
        SUM("output_count")                        AS total_outputs,
        SUM(CASE WHEN is_cj=1 THEN "input_count"  END)  AS cj_inputs,
        SUM(CASE WHEN is_cj=1 THEN "output_count" END)  AS cj_outputs,
        SUM(input_val)                             AS total_volume,
        SUM(CASE WHEN is_cj=1 THEN input_val END)  AS cj_volume
    FROM tx_classified
    GROUP BY month_num
),
/* convert to percentages                                          */
month_pct AS (
    SELECT
        month_num,
        ROUND(cj_tx      * 100.0 / NULLIF(total_tx    ,0), 1) AS pct_tx_coinjoin,
        ROUND(((cj_inputs* 100.0 / NULLIF(total_inputs,0))
             + (cj_outputs*100.0 / NULLIF(total_outputs,0)))/2 , 1)
                                                          AS pct_utxo_coinjoin,
        ROUND(cj_volume * 100.0 / NULLIF(total_volume ,0), 1) AS pct_volume_coinjoin
    FROM month_stats
)
SELECT
    month_num           AS month_with_max_cj_volume,
    pct_tx_coinjoin,
    pct_utxo_coinjoin,
    pct_volume_coinjoin
FROM month_pct
ORDER BY pct_volume_coinjoin DESC NULLS LAST
LIMIT 1;