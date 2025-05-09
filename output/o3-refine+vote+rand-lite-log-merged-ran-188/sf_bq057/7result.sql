WITH tx AS (   -- all Bitcoin transactions for 2021
    SELECT  "hash"                               AS tx_hash ,
            "output_count"                       AS out_cnt ,
            "input_value"                        AS in_val ,
            "output_value"                       AS out_val ,
            EXTRACT(month FROM TO_TIMESTAMP("block_timestamp"/1000000)) AS mth
    FROM    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE   EXTRACT(year  FROM TO_TIMESTAMP("block_timestamp"/1000000)) = 2021
),  

dup_tx AS (     -- txs that have at least one duplicated output amount
    SELECT  DISTINCT "transaction_hash" AS tx_hash
    FROM    (
            SELECT  "transaction_hash","value",COUNT(*) AS c
            FROM    CRYPTO.CRYPTO_BITCOIN.OUTPUTS
            GROUP   BY "transaction_hash","value"
            HAVING  COUNT(*) > 1
    )
),  

coinjoin_tx AS (    -- candidate CoinJoin txs
    SELECT  t.tx_hash , t.mth
    FROM    tx  t
    JOIN    dup_tx d   ON d.tx_hash = t.tx_hash
    WHERE   t.out_cnt > 2
      AND   NVL(t.out_val,0) <= NVL(t.in_val,0)
),  

month_tx AS (       -- transaction & volume counts per month
    SELECT  tx.mth                                            AS month ,
            COUNT(*)                                          AS tot_tx ,
            SUM(CASE WHEN cj.tx_hash IS NOT NULL THEN 1 END)  AS cj_tx ,
            SUM(tx.in_val)                                    AS tot_vol ,
            SUM(CASE WHEN cj.tx_hash IS NOT NULL THEN tx.in_val END) AS cj_vol
    FROM    tx
    LEFT    JOIN coinjoin_tx cj ON cj.tx_hash = tx.tx_hash
    GROUP   BY tx.mth
),  

input_stats AS (    -- input‑UTXO counts
    SELECT  tx.mth                                            AS month ,
            COUNT(*)                                          AS tot_in ,
            SUM(CASE WHEN cj.tx_hash IS NOT NULL THEN 1 END)  AS cj_in
    FROM    CRYPTO.CRYPTO_BITCOIN.INPUTS  i
    JOIN    tx  ON tx.tx_hash = i."transaction_hash"
    LEFT    JOIN coinjoin_tx cj ON cj.tx_hash = i."transaction_hash"
    GROUP   BY tx.mth
),  

output_stats AS (   -- output‑UTXO counts
    SELECT  tx.mth                                            AS month ,
            COUNT(*)                                          AS tot_out ,
            SUM(CASE WHEN cj.tx_hash IS NOT NULL THEN 1 END)  AS cj_out
    FROM    CRYPTO.CRYPTO_BITCOIN.OUTPUTS o
    JOIN    tx  ON tx.tx_hash = o."transaction_hash"
    LEFT    JOIN coinjoin_tx cj ON cj.tx_hash = o."transaction_hash"
    GROUP   BY tx.mth
),  

metrics AS (        -- assemble all required percentages
    SELECT  mt.month ,
            ROUND(100.0 * mt.cj_tx / mt.tot_tx , 1)                     AS pct_tx_coinjoin ,
            ROUND(( 100.0 * ins.cj_in  / ins.tot_in
                  + 100.0 * outs.cj_out / outs.tot_out ) / 2 , 1)       AS pct_utxo_coinjoin ,
            ROUND(100.0 * mt.cj_vol / mt.tot_vol , 1)                   AS pct_volume_coinjoin
    FROM    month_tx     mt
    JOIN    input_stats  ins  USING (month)
    JOIN    output_stats outs USING (month)
)

SELECT  month                                   AS "MONTH" ,
        pct_tx_coinjoin                         AS "PCT_TRANSACTIONS_COINJOIN" ,
        pct_utxo_coinjoin                       AS "PCT_UTXOS_COINJOIN" ,
        pct_volume_coinjoin                     AS "PCT_VOLUME_COINJOIN"
FROM    metrics
ORDER   BY pct_volume_coinjoin DESC, month
LIMIT   1;