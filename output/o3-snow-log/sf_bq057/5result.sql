WITH tx AS (
    /*  all Bitcoin transactions from 2021  */
    SELECT
        "hash",
        "block_timestamp",
        "output_count",
        "input_count",
        "output_value",
        "input_value",
        MONTH( TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) )          AS month_num
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE YEAR( TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) ) = 2021
), out_stats AS (
    /*  per-transaction statistics about duplicate output values  */
    SELECT
        t."hash",
        COUNT(*)                                               AS out_total,
        COUNT(DISTINCT (f.value:"value")::NUMBER)              AS out_distinct
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS  t,
         LATERAL FLATTEN( INPUT => t."outputs" )               f
    WHERE YEAR( TO_TIMESTAMP_NTZ(t."block_timestamp" / 1000000) ) = 2021
    GROUP BY t."hash"
), tx_flagged AS (
    /*  flag CoinJoin transactions                                   */
    SELECT
        t.*,
        os.out_total,
        os.out_distinct,
        CASE
            WHEN t."output_count" > 2
             AND t."output_value" <= t."input_value"
             AND os.out_distinct < os.out_total
            THEN 1 ELSE 0
        END                                                    AS is_coinjoin
    FROM tx  t
    JOIN out_stats os   ON t."hash" = os."hash"
), monthly AS (
    /*  aggregate monthly numbers                                   */
    SELECT
        month_num,
        COUNT(*)                                            AS total_tx,
        SUM(is_coinjoin)                                    AS cj_tx,
        SUM("input_count")                                  AS total_inputs,
        SUM("output_count")                                 AS total_outputs,
        COALESCE( SUM( CASE WHEN is_coinjoin=1 THEN "input_count"  END ),0)   AS cj_inputs,
        COALESCE( SUM( CASE WHEN is_coinjoin=1 THEN "output_count" END ),0)   AS cj_outputs,
        SUM("input_value")                                  AS total_vol,
        COALESCE( SUM( CASE WHEN is_coinjoin=1 THEN "input_value"  END ),0)   AS cj_vol
    FROM tx_flagged
    GROUP BY month_num
), calc AS (
    /*  percentages                                                  */
    SELECT
        month_num                                                      AS month,
        ROUND( cj_tx      * 100.0 / NULLIF(total_tx     ,0), 1) AS pct_tx_coinjoin,
        ROUND(
              ( (cj_inputs * 100.0 / NULLIF(total_inputs ,0))
              + (cj_outputs* 100.0 / NULLIF(total_outputs,0)) ) / 2
        , 1)                                                   AS pct_utxo_coinjoin,
        ROUND( cj_vol     * 100.0 / NULLIF(total_vol    ,0), 1) AS pct_vol_coinjoin
    FROM monthly
)
SELECT *
FROM calc
ORDER BY pct_vol_coinjoin DESC NULLS LAST
LIMIT 1;