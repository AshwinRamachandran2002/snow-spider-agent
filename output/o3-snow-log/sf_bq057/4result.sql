/* ---------------------------------------------------------------
   CoinJoin statistics per month for Bitcoin in 2021
   ---------------------------------------------------------------
   CoinJoin definition:
     • >2 outputs
     • total output_value ≤ total input_value
     • ≥2 outputs having at least two identical values
   --------------------------------------------------------------- */
WITH tx_2021 AS (   -- Bitcoin transactions mined in 2021
    SELECT
        "hash"                                            AS tx_hash,
        "outputs"                                         AS outs,
        CAST("input_count"   AS NUMBER)                   AS in_cnt,
        CAST("output_count"  AS NUMBER)                   AS out_cnt,
        CAST("input_value"   AS NUMBER)                   AS in_val,
        CAST("output_value"  AS NUMBER)                   AS out_val,
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP("block_timestamp" / 1e6)
        )                                                 AS month_start,
        EXTRACT(month FROM TO_TIMESTAMP("block_timestamp" / 1e6))
                                                         AS month_num
    FROM   CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE  TO_CHAR(TO_TIMESTAMP("block_timestamp" / 1e6),'YYYY') = '2021'
),
/* ---------------------------------------------------------------
   Transactions that contain at least two identical output values
   --------------------------------------------------------------- */
dup_output_txs AS (
    SELECT DISTINCT
           t.tx_hash
    FROM   tx_2021 t
           ,LATERAL FLATTEN(input => t.outs) f
    GROUP  BY t.tx_hash ,
             CAST(f.value:"value" AS STRING)              -- treat value as string to avoid numeric cast issues
    HAVING COUNT(*) >= 2
),
/* ---------------------------------------------------------------
   Flag CoinJoin transactions
   --------------------------------------------------------------- */
coinjoin_txs AS (
    SELECT DISTINCT t.tx_hash
    FROM   tx_2021        t
    JOIN   dup_output_txs d USING (tx_hash)
    WHERE  t.out_cnt  > 2
      AND  t.out_val <= t.in_val
),
tx_flagged AS (
    SELECT t.* ,
           IFF(c.tx_hash IS NULL, 0, 1) AS is_coinjoin
    FROM   tx_2021 t
    LEFT  JOIN coinjoin_txs c USING (tx_hash)
),
/* ---------------------------------------------------------------
   Monthly aggregates
   --------------------------------------------------------------- */
monthly AS (
    SELECT
        month_start ,
        month_num                                                    AS month ,
        COUNT(*)                                                     AS total_tx ,
        SUM(in_cnt)                                                  AS total_inputs ,
        SUM(out_cnt)                                                 AS total_outputs ,
        SUM(out_val)                                                 AS total_vol ,
        SUM(is_coinjoin)                                             AS cj_tx ,
        SUM(CASE WHEN is_coinjoin=1 THEN in_cnt  ELSE 0 END)         AS cj_inputs ,
        SUM(CASE WHEN is_coinjoin=1 THEN out_cnt ELSE 0 END)         AS cj_outputs ,
        SUM(CASE WHEN is_coinjoin=1 THEN out_val ELSE 0 END)         AS cj_vol
    FROM   tx_flagged
    GROUP BY month_start , month_num
),
/* ---------------------------------------------------------------
   Percentages (rounded to 1 decimal)
   --------------------------------------------------------------- */
metrics AS (
    SELECT
        month                                                   ,
        ROUND(cj_tx    *100.0 / NULLIF(total_tx   ,0),1) AS pct_tx_coinjoin ,
        ROUND(( (cj_inputs *100.0 / NULLIF(total_inputs ,0)) +
                (cj_outputs*100.0 / NULLIF(total_outputs,0)) )/2 ,1)
                                                          AS pct_utxo_coinjoin ,
        ROUND(cj_vol   *100.0 / NULLIF(total_vol  ,0),1) AS pct_vol_coinjoin
    FROM   monthly
)
/* ---------------------------------------------------------------
   Month with the highest CoinJoin volume share
   --------------------------------------------------------------- */
SELECT *
FROM   metrics
ORDER  BY pct_vol_coinjoin DESC NULLS LAST
LIMIT  1;