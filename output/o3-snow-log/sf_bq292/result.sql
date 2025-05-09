WITH tx_base AS (  -- Bitcoin txs from July-2023 onward
    SELECT
        "hash"                                                AS txhash ,
        "input_count"::NUMBER                                 AS input_cnt ,
        "output_count"::NUMBER                                AS output_cnt ,
        "input_value"::NUMBER                                 AS input_val ,
        "output_value"::NUMBER                                AS output_val ,
        ("input_count"::NUMBER + "output_count"::NUMBER)      AS utxo_cnt ,
        "block_timestamp"::NUMBER                             AS ts ,
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000))  AS month ,
        PARSE_JSON("outputs")                                 AS outs_json
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" >= 1688169600000000          -- 2023-07-01 00:00:00 UTC in µs
),                                                         
outputs_stats AS (        -- how many outputs & how many distinct values each tx has
    SELECT
        txhash ,
        COUNT(*)                                              AS total_outs ,
        COUNT(DISTINCT (o.value:"value")::NUMBER)             AS distinct_vals
    FROM   tx_base ,
           LATERAL FLATTEN( INPUT => outs_json ) o
    GROUP  BY txhash
),                                                         
classified AS (          -- flag CoinJoin transactions
    SELECT
        b.* ,
        CASE 
            WHEN b.output_cnt > 2
             AND b.output_val <= b.input_val
             AND b.output_cnt > s.distinct_vals
            THEN 1 ELSE 0 
        END                                                  AS is_coinjoin
    FROM   tx_base  b
    JOIN   outputs_stats s
           ON b.txhash = s.txhash
),                                                         
monthly AS (            -- aggregate monthly metrics
    SELECT
        month ,
        COUNT(*)                                         AS total_tx ,
        SUM(is_coinjoin)                                AS coinjoin_tx ,
        SUM(utxo_cnt)                                   AS total_utxos ,
        SUM( CASE WHEN is_coinjoin = 1 THEN utxo_cnt  ELSE 0 END )  AS coinjoin_utxos ,
        SUM(input_val)                                  AS total_volume ,
        SUM( CASE WHEN is_coinjoin = 1 THEN input_val ELSE 0 END )  AS coinjoin_volume
    FROM   classified
    GROUP  BY month
)                                                         
SELECT
    month ,
    ROUND( coinjoin_tx      * 100.0 / NULLIF(total_tx     ,0) , 4 )  AS pct_transactions_coinjoin ,
    ROUND( coinjoin_utxos   * 100.0 / NULLIF(total_utxos  ,0) , 4 )  AS pct_utxos_coinjoin ,
    ROUND( coinjoin_volume  * 100.0 / NULLIF(total_volume ,0) , 4 )  AS pct_volume_coinjoin
FROM   monthly
ORDER  BY month;