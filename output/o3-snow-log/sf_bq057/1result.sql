WITH tx_2021 AS (   /* 2021 BTC transactions with needed fields + raw outputs */
    SELECT
        "hash",
        "block_timestamp",
        "input_value" :: FLOAT  AS in_value,
        "output_value":: FLOAT  AS out_value,
        "input_count"           AS in_cnt,
        "output_count"          AS out_cnt,
        "outputs"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE DATE_TRUNC('YEAR', TO_TIMESTAMP("block_timestamp"/1000000)) = '2021-01-01'
),                          /* individual output values                                 */
output_values AS (
    SELECT
        t."hash",
        TRY_TO_NUMBER((f.value:"value")::STRING) AS out_val
    FROM tx_2021 t,
         LATERAL FLATTEN(INPUT => PARSE_JSON(t."outputs")) f
),                          /* txs that have ≥2 equal-value outputs                     */
dup_outputs AS (
    SELECT DISTINCT "hash", 1 AS has_equal_vals
    FROM (
        SELECT "hash", out_val, COUNT(*) cnt
        FROM  output_values
        GROUP BY "hash", out_val
        HAVING cnt >= 2
    )
),                          /* base table with helper flag                              */
base AS (
    SELECT
        t."hash",
        t."block_timestamp",
        t.in_value,
        t.out_value,
        t.in_cnt,
        t.out_cnt,
        COALESCE(d.has_equal_vals,0) AS has_equal_vals
    FROM tx_2021 t
    LEFT JOIN dup_outputs d ON t."hash" = d."hash"
),                          /* classify CoinJoin & metrics                              */
calc AS (
    SELECT
        EXTRACT(MONTH FROM TO_TIMESTAMP("block_timestamp"/1000000))  AS mth,
        IFF( out_cnt > 2
             AND out_value <= in_value
             AND has_equal_vals = 1 , 1 , 0)                         AS is_cj,
        in_cnt                                                      AS in_ux,
        out_cnt                                                     AS out_ux,
        out_value                                                   AS vol
    FROM base
),                          /* monthly aggregation                                      */
agg AS (
    SELECT
        mth                                           AS month,
        SUM(is_cj)                                    AS cj_tx,
        COUNT(*)                                      AS tot_tx,
        SUM(IFF(is_cj=1,in_ux ,0))                    AS cj_in_utxo,
        SUM(in_ux)                                    AS tot_in_utxo,
        SUM(IFF(is_cj=1,out_ux,0))                    AS cj_out_utxo,
        SUM(out_ux)                                   AS tot_out_utxo,
        SUM(IFF(is_cj=1,vol ,0))                      AS cj_vol,
        SUM(vol)                                      AS tot_vol
    FROM calc
    GROUP BY month
),                          /* percentages                                             */
metrics AS (
    SELECT
        month,
        (cj_tx *100.0)/tot_tx                                           AS pct_tx,
        ((cj_in_utxo*100.0)/tot_in_utxo + (cj_out_utxo*100.0)/tot_out_utxo)/2
                                                                         AS pct_utxo,
        (cj_vol*100.0)/tot_vol                                          AS pct_vol
    FROM agg
)
SELECT
    month                                        AS month_with_max_cj_volume,
    ROUND(pct_tx  ,1)                            AS pct_transactions_coinjoin,
    ROUND(pct_utxo,1)                            AS pct_utxos_coinjoin,
    ROUND(pct_vol ,1)                            AS pct_volume_coinjoin
FROM metrics
ORDER BY pct_vol DESC NULLS LAST
LIMIT 1;