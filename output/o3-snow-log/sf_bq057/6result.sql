WITH tx_2021 AS (     -- all Bitcoin transactions in 2021
    SELECT  "hash"                                                    AS tx_hash ,
            DATE_TRUNC('month', TO_TIMESTAMP_NTZ("block_timestamp"/1e6))  AS month_start ,
            "output_count"::INT                                       AS out_cnt ,
            "input_count"::INT                                        AS in_cnt ,
            "output_value"::FLOAT                                     AS out_val ,
            "input_value"::FLOAT                                      AS in_val ,
            "outputs"                                                 AS outputs
    FROM   CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE  TO_CHAR( TO_TIMESTAMP_NTZ("block_timestamp"/1e6) ,'YYYY') = '2021'
),

/* does the tx contain ≥2 identical-value outputs ? */
dup_outputs AS (    
    SELECT  tx_hash ,
            MAX( CASE WHEN cnt >= 2 THEN 1 ELSE 0 END ) AS has_dup
    FROM  (
        SELECT  t.tx_hash ,
                (f.value:"value")::FLOAT   AS o_val ,
                COUNT(*)                   AS cnt
        FROM   tx_2021  t
        CROSS JOIN LATERAL FLATTEN (INPUT => t.outputs) f
        GROUP  BY t.tx_hash , o_val
    ) s
    GROUP  BY tx_hash
),

/* flag CoinJoin transactions */
flagged AS (
    SELECT  t.* ,
            COALESCE(d.has_dup,0) AS has_dup ,
            CASE
                 WHEN t.out_cnt > 2
                  AND COALESCE(t.out_val,0) <= COALESCE(t.in_val,0)
                  AND COALESCE(d.has_dup,0) = 1
                 THEN 1 ELSE 0
            END  AS is_coinjoin
    FROM   tx_2021 t
    LEFT   JOIN dup_outputs d  ON d.tx_hash = t.tx_hash
),

/* monthly aggregates */
monthly AS (
    SELECT  month_start ,
            COUNT(*)                                           AS total_tx ,
            SUM(is_coinjoin)                                   AS cj_tx ,
            SUM(COALESCE(out_val,0))                           AS total_vol ,
            SUM(CASE WHEN is_coinjoin=1 THEN COALESCE(out_val,0) END)  AS cj_vol ,
            SUM(in_cnt)                                        AS tot_in_utxo ,
            SUM(out_cnt)                                       AS tot_out_utxo ,
            SUM(CASE WHEN is_coinjoin=1 THEN in_cnt  END)      AS cj_in_utxo ,
            SUM(CASE WHEN is_coinjoin=1 THEN out_cnt END)      AS cj_out_utxo
    FROM    flagged
    GROUP   BY month_start
),

/* convert to percentages */
metrics AS (
    SELECT  month_start ,
            100.0 * cj_tx / NULLIF(total_tx ,0)                                            AS pct_tx ,
            100.0 * ( (cj_in_utxo / NULLIF(tot_in_utxo ,0)) +
                       (cj_out_utxo/ NULLIF(tot_out_utxo,0)) ) / 2                         AS pct_utxo ,
            100.0 * cj_vol / NULLIF(total_vol ,0)                                          AS pct_vol
    FROM    monthly
)

SELECT  MONTH(month_start)                      AS month ,
        ROUND(pct_tx  ,1)  AS pct_coinjoin_transactions ,
        ROUND(pct_utxo,1)  AS pct_coinjoin_utxos ,
        ROUND(pct_vol ,1)  AS pct_coinjoin_volume
FROM    metrics
ORDER BY pct_vol DESC NULLS LAST
LIMIT 1;