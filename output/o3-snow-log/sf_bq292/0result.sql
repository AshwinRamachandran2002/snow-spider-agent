WITH base_tx AS (   -- Bitcoin transactions from July-2023 onward
    SELECT
        "hash"                                               AS tx_hash ,
        "block_timestamp"                                    AS ts_usec ,
        DATE_TRUNC( 'month'
                  , TO_TIMESTAMP( "block_timestamp" / 1e6 )  -- micro-seconds → TIMESTAMP
                  )                                          AS month ,
        "output_count"                                       AS out_cnt ,
        "input_count"                                        AS in_cnt ,
        TO_NUMBER( "input_value" )                           AS in_val ,
        TO_NUMBER( "output_value" )                          AS out_val ,
        "outputs"                                            AS outs_arr
    FROM   CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE  "block_timestamp" >= 1688169600000000             -- 2023-07-01 00:00:00 UTC (µs)
)
, dup_check AS (        -- how many distinct vs. total output values each tx has
    SELECT
        tx_hash ,
        COUNT(*)                              AS tot_outs ,
        COUNT( DISTINCT TO_NUMBER( f.value:"value" ) ) 
                                             AS distinct_vals
    FROM   base_tx ,
           LATERAL FLATTEN( input => outs_arr ) AS f
    GROUP  BY tx_hash
)
, classified AS (       -- label CoinJoin transactions
    SELECT
        b.* ,
        CASE
            WHEN b.out_cnt > 2
             AND b.out_val <= b.in_val
             AND d.tot_outs  > d.distinct_vals     -- ≥ 2 identical-value outputs
            THEN 1 ELSE 0
        END                                     AS is_coinjoin
    FROM   base_tx  b
    JOIN   dup_check d USING ( tx_hash )
)
SELECT
    TO_CHAR( month , 'YYYY-MM' )                          AS "month" ,

    /* (1) % of transactions that are CoinJoins */
    SUM( is_coinjoin )                                   AS coinjoin_tx_cnt ,
    COUNT(*)                                             AS total_tx_cnt ,
    ROUND( 100 * SUM( is_coinjoin )      / COUNT(*) , 4) AS coinjoin_tx_pct ,

    /* (2) % of UTXOs (inputs + outputs) involved in CoinJoins */
    SUM( CASE WHEN is_coinjoin=1 THEN in_cnt+out_cnt ELSE 0 END )   AS coinjoin_utxos ,
    SUM( in_cnt + out_cnt )                                          AS total_utxos ,
    ROUND( 100 * SUM( CASE WHEN is_coinjoin=1 THEN in_cnt+out_cnt ELSE 0 END )
                 / NULLIF( SUM( in_cnt + out_cnt ) ,0) , 4)          AS coinjoin_utxo_pct ,

    /* (3) % of volume (input value) that is CoinJoins */
    SUM( CASE WHEN is_coinjoin=1 THEN in_val ELSE 0 END )           AS coinjoin_volume ,
    SUM( in_val )                                                   AS total_volume ,
    ROUND( 100 * SUM( CASE WHEN is_coinjoin=1 THEN in_val ELSE 0 END )
                 / NULLIF( SUM( in_val ) ,0) , 4)                   AS coinjoin_volume_pct
FROM   classified
GROUP  BY month
ORDER  BY month;