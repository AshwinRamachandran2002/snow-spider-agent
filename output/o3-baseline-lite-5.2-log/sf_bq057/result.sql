WITH tx AS (   /*  all Bitcoin txs in 2021  */
    SELECT 
        "hash",
        "outputs",
        MONTH(TO_TIMESTAMP("block_timestamp"/1e6))             AS mth,
        TO_NUMBER("input_value")                               AS in_val,
        TO_NUMBER("output_value")                              AS out_val,
        "input_count"                                          AS in_utxo,
        "output_count"                                         AS out_utxo
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE YEAR(TO_TIMESTAMP("block_timestamp"/1e6)) = 2021
),                                                             
dup AS (   /* outputs per tx & how many distinct amounts  */   
    SELECT  
        t."hash",
        COUNT(*)                              AS out_cnt,
        COUNT(DISTINCT (f.value:"value")::NUMBER)  AS distinct_vals
    FROM tx t,
         LATERAL FLATTEN(t."outputs") f
    GROUP BY t."hash"
),                                                             
coinjoin AS (   /* flag CoinJoin txs  */
    SELECT  
        t.*,
        CASE 
           WHEN t.out_utxo > 2
            AND t.out_val <= t.in_val
            AND d.out_cnt > d.distinct_vals    /* ≥ 2 equal‑value outputs */
           THEN 1 ELSE 0 
        END                                     AS is_cj
    FROM tx t
    JOIN dup d ON t."hash" = d."hash"
),                                                             
month_stats AS (   /* monthly aggregates  */
    SELECT
        mth                                                         AS month,
        /* % of all txs that are CoinJoin */
        ROUND(100.0*SUM(is_cj)/COUNT(*) ,1)                         AS pct_cj_txs,
        /* % of UTXOs (avg of input & output sides) in CoinJoin  */
        ROUND( 50.0 * ( SUM(CASE WHEN is_cj=1 THEN in_utxo  END)/SUM(in_utxo)
                     +  SUM(CASE WHEN is_cj=1 THEN out_utxo END)/SUM(out_utxo) ),1) AS pct_cj_utxo,
        /* % of total BTC volume that is CoinJoin */
        ROUND(100.0*SUM(CASE WHEN is_cj=1 THEN out_val END)
                   /NULLIF(SUM(out_val),0),1)                      AS pct_cj_vol
    FROM coinjoin
    GROUP BY mth
),                                                             
best AS (   /* month with highest CoinJoin‑volume share */
    SELECT *
    FROM month_stats
    ORDER BY pct_cj_vol DESC NULLS LAST
    LIMIT 1
)                                                              
SELECT 
    month                                   AS "MONTH_2021",
    pct_cj_txs                              AS "PCT_COINSJOIN_TRANSACTIONS",
    pct_cj_utxo                             AS "PCT_UTXOS_IN_COINSJOIN",
    pct_cj_vol                              AS "PCT_VOLUME_IN_COINSJOIN"
FROM best;