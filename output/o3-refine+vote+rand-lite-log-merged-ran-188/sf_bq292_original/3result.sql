WITH
-- 1.  Bitcoin transactions since 1‑Jul‑2023
tx AS (
    SELECT
        "hash"                                             AS tx_hash ,
        "block_timestamp"                                  AS blk_ts_micro ,
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp"/1e6))  AS month ,
        "input_count"                                      AS in_cnt ,
        "output_count"                                     AS out_cnt ,
        "input_value" :: DOUBLE                            AS in_val ,
        "output_value":: DOUBLE                            AS out_val
    FROM  CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" >= 1688169600000000         -- 2023‑07‑01 00:00:00 UTC (µs)
),
-- 2.  Transactions that have ≥ 2 identical–value outputs
dup_out_tx AS (
    SELECT DISTINCT "transaction_hash" AS tx_hash
    FROM (
        SELECT "transaction_hash" , "value"
        FROM  CRYPTO.CRYPTO_BITCOIN.OUTPUTS
        WHERE "block_timestamp" >= 1688169600000000
        GROUP BY "transaction_hash" , "value"
        HAVING COUNT(*) > 1                 -- duplicated output value
    )
),
-- 3.  Flag CoinJoin candidates
tx_flag AS (
    SELECT
        t.* ,
        CASE
            WHEN t.out_cnt > 2
             AND t.out_val <= t.in_val
             AND d.tx_hash IS NOT NULL
            THEN 1 ELSE 0
        END                                                AS is_coinjoin
    FROM tx  t
    LEFT JOIN dup_out_tx d
           ON t.tx_hash = d.tx_hash
),
-- 4.  Monthly aggregation (transactions, UTXOs, volume)
monthly AS (
    SELECT
        month ,
        SUM(is_coinjoin)                                   AS cj_tx_cnt ,
        COUNT(*)                                           AS total_tx_cnt ,
        SUM( IFF(is_coinjoin=1 , in_cnt+out_cnt , 0) )     AS cj_utxos ,
        SUM( in_cnt + out_cnt )                            AS total_utxos ,
        SUM( IFF(is_coinjoin=1 , in_val , 0) )             AS cj_volume ,
        SUM( in_val )                                      AS total_volume
    FROM tx_flag
    GROUP BY month
)
-- 5.  Final result with percentages
SELECT
    month                                                    ,
    cj_tx_cnt        AS "COINJOIN_TXS"                       ,
    total_tx_cnt     AS "TOTAL_TXS"                          ,
    ROUND( 100.0 * cj_tx_cnt  / total_tx_cnt , 4)  AS "TX_PCT_COINJOIN"      ,
    cj_utxos         AS "COINJOIN_UTXOS"                     ,
    total_utxos      AS "TOTAL_UTXOS"                        ,
    ROUND( 100.0 * cj_utxos / total_utxos , 4)  AS "UTXO_PCT_COINJOIN"       ,
    cj_volume        AS "COINJOIN_VOLUME"                    ,
    total_volume     AS "TOTAL_VOLUME"                       ,
    ROUND( 100.0 * cj_volume / total_volume , 4) AS "VOLUME_PCT_COINJOIN"
FROM monthly
ORDER BY month;