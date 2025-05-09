WITH tx AS (   /* --- Bitcoin transactions since 1‑Jul‑2023 --- */
    SELECT
        "hash"                               AS tx_hash ,
        "output_count"                       AS out_cnt ,
        "input_count"                        AS in_cnt  ,
        "input_value" ::FLOAT                AS in_val ,
        "output_value"::FLOAT                AS out_val,
        "outputs"                            AS outs   ,
        TO_DATE( TO_TIMESTAMP("block_timestamp"/1e6) ) AS blk_day
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE TO_DATE( TO_TIMESTAMP("block_timestamp"/1e6) ) >= '2023-07-01'
),

dup AS (       /* --- per‑tx counts of outputs & distinct values --- */
    SELECT
        t.tx_hash ,
        COUNT(*)                                            AS outs_total ,
        COUNT( DISTINCT CAST( f.value:"value" AS FLOAT) )   AS vals_dist
    FROM tx t
         ,LATERAL FLATTEN( INPUT => t.outs ) f              -- one row per output
    GROUP BY t.tx_hash
),

cj_flagged AS ( /* --- identify CoinJoin transactions --- */
    SELECT
        t.* ,
        d.outs_total ,
        d.vals_dist ,
        CASE
             WHEN t.out_cnt > 2
              AND t.out_val <= t.in_val
              AND d.vals_dist < d.outs_total    -- ≥1 repeated value
             THEN 1 ELSE 0
        END                                    AS is_coinjoin
    FROM tx t
    JOIN dup d USING (tx_hash)
),

monthly AS (    /* --- aggregate monthly metrics --- */
    SELECT
        DATE_TRUNC('month', blk_day)                           AS month ,
        COUNT(*)                                               AS total_tx ,
        SUM(is_coinjoin)                                       AS cj_tx ,
        SUM(in_cnt)                                            AS total_inputs ,
        SUM(out_cnt)                                           AS total_outputs ,
        SUM(CASE WHEN is_coinjoin=1 THEN in_cnt  END)          AS cj_inputs ,
        SUM(CASE WHEN is_coinjoin=1 THEN out_cnt END)          AS cj_outputs ,
        SUM(in_val)                                            AS total_volume ,
        SUM(CASE WHEN is_coinjoin=1 THEN in_val END)           AS cj_volume
    FROM cj_flagged
    GROUP BY DATE_TRUNC('month', blk_day)
)

SELECT
    month                                                                       ,
    ROUND( 100 * cj_tx      / NULLIF(total_tx     ,0) ,4) AS pct_coinjoin_tx    ,
    ROUND( 100 * ( (cj_inputs / NULLIF(total_inputs ,0)) +
                   (cj_outputs/ NULLIF(total_outputs,0)) ) / 2 ,4) AS pct_utxos ,
    ROUND( 100 * cj_volume  / NULLIF(total_volume ,0) ,4) AS pct_volume
FROM monthly
ORDER BY month