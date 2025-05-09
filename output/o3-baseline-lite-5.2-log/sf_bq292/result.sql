/*------------------------------------------------------------
Monthly CoinJoin share in Bitcoin since 2023‑07
--------------------------------------------------------------*/
WITH tx AS (   /* All BTC transactions from July‑2023 on */
    SELECT
        "hash"                                           AS tx_hash ,
        TO_CHAR( TO_TIMESTAMP( "block_timestamp" / 1e6 )
                , 'YYYY-MM')                             AS month ,
        CAST("input_count"  AS FLOAT)                    AS in_cnt ,
        CAST("output_count" AS FLOAT)                    AS out_cnt ,
        CAST("input_value"  AS FLOAT)                    AS in_val ,
        CAST("output_value" AS FLOAT)                    AS out_val
    FROM   CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE  "block_timestamp" >= 1688169600000000      -- 2023‑07‑01 00:00:00 UTC (µs)
),
outs AS (      /* per‑transaction output statistics */
    SELECT
        "transaction_hash"                              AS tx_hash ,
        COUNT(*)                                        AS outs_total ,
        COUNT(DISTINCT "value")                         AS outs_distinct
    FROM   CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    WHERE  "block_timestamp" >= 1688169600000000
    GROUP  BY "transaction_hash"
),
joined AS (     /* enrich tx with output‑duplication flag */
    SELECT
        t.* ,
        o.outs_total ,
        o.outs_distinct ,
        /* CoinJoin definition:
             – more than 2 outputs
             – total output value ≤ total input value
             – duplicated output values  (distinct < total)  */
        CASE
            WHEN t.out_cnt    > 2
             AND t.out_val    <= t.in_val
             AND o.outs_distinct < o.outs_total
            THEN 1 ELSE 0
        END                                             AS is_coinjoin
    FROM   tx t
    LEFT  JOIN outs o
           ON o.tx_hash = t.tx_hash
)
SELECT
    month                                                              ,
    COUNT_IF(is_coinjoin = 1)                                  AS coinjoin_tx_cnt ,
    COUNT(*)                                                   AS total_tx_cnt    ,
    ROUND( 100 * COUNT_IF(is_coinjoin = 1)   / NULLIF(COUNT(*),0)                ,4) AS pct_tx           ,
    ROUND( 100 * SUM( IFF(is_coinjoin = 1 , in_cnt+out_cnt , 0) )
                / NULLIF( SUM(in_cnt+out_cnt) ,0)                                 ,4) AS pct_utxos       ,
    ROUND( 100 * SUM( IFF(is_coinjoin = 1 , in_val          , 0) )
                / NULLIF( SUM(in_val)        ,0)                                 ,4) AS pct_volume
FROM   joined
GROUP  BY month
ORDER  BY month;