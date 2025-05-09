/*  Month in 2021 with the highest CoinJoin share – robust to months with zero CoinJoins  */
WITH tx_2021 AS (      -- every Bitcoin transaction mined in 2021
    SELECT  "hash"                                                  AS tx_hash ,
            EXTRACT( MONTH FROM TO_TIMESTAMP( "block_timestamp"/1e6 ) ) AS mth ,
            "input_count"                                           AS in_cnt ,
            "output_count"                                          AS out_cnt ,
            "input_value"                                           AS in_val ,
            "output_value"                                          AS out_val
    FROM    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE   TO_TIMESTAMP( "block_timestamp"/1e6 )
            BETWEEN '2021-01-01' AND '2021-12-31 23:59:59'
),
/*  a CoinJoin must have >2 outputs AND at least two outputs of identical value           */
coinjoin_tx AS (
    SELECT  t.*
    FROM    tx_2021 t
    WHERE   t.out_cnt > 2
      AND   EXISTS ( SELECT 1
                     FROM   CRYPTO.CRYPTO_BITCOIN.OUTPUTS o
                     WHERE  o."transaction_hash" = t.tx_hash
                     GROUP  BY o."value"
                     HAVING COUNT(*) >= 2 )
),
-- monthly totals for all txs
all_month AS (
    SELECT  mth,
            COUNT(*)            AS total_tx,
            SUM(in_cnt)         AS total_in_utxos,
            SUM(out_cnt)        AS total_out_utxos,
            SUM(out_val)        AS total_btc
    FROM    tx_2021
    GROUP   BY mth
),
-- monthly totals for CoinJoin txs
cj_month AS (
    SELECT  mth,
            COUNT(*)            AS cj_tx,
            SUM(in_cnt)         AS cj_in_utxos,
            SUM(out_cnt)        AS cj_out_utxos,
            SUM(out_val)        AS cj_btc
    FROM    coinjoin_tx
    GROUP   BY mth
),
metrics AS (
    SELECT  a.mth                                           AS month ,
            COALESCE(cj.cj_tx        , 0)          AS cj_tx ,
            COALESCE(cj.cj_in_utxos  , 0)          AS cj_in ,
            COALESCE(cj.cj_out_utxos , 0)          AS cj_out,
            COALESCE(cj.cj_btc       , 0)          AS cj_btc,
            a.total_tx,
            a.total_in_utxos,
            a.total_out_utxos,
            a.total_btc
    FROM    all_month a
    LEFT JOIN cj_month cj  USING (mth)
),
final AS (
    SELECT  month,
            /* % CoinJoin transactions            */
            CASE WHEN total_tx = 0 THEN 0
                 ELSE ROUND( 100.0 * cj_tx / total_tx , 1) END      AS pct_tx,
            /* % UTXOs involved (average of inputs & outputs) */
            CASE WHEN total_in_utxos = 0 OR total_out_utxos = 0 THEN 0
                 ELSE ROUND( 50.0 * (  cj_in  / total_in_utxos
                                     + cj_out / total_out_utxos ) , 1) END
                                                                    AS pct_utxo,
            /* % of BTC volume                            */
            CASE WHEN total_btc = 0 THEN 0
                 ELSE ROUND( 100.0 * cj_btc / total_btc , 1) END    AS pct_vol
    FROM    metrics
)
SELECT  month               AS month_with_max_pct_coinjoin_volume ,
        pct_tx              AS pct_coinjoin_transactions ,
        pct_utxo            AS pct_coinjoin_utxos ,
        pct_vol             AS pct_coinjoin_volume
FROM    final
ORDER BY pct_vol DESC NULLS LAST
LIMIT 1;