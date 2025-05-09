WITH tx AS (   /* all BTC transactions from Jul-2023 forward */
    SELECT
        "block_timestamp_month"               AS month ,
        "hash"                    AS tx_hash ,
        "output_count" ::INT      AS output_cnt ,
        "input_count"  ::INT      AS input_cnt ,
        "input_value"  ::FLOAT    AS input_val ,
        "output_value" ::FLOAT    AS output_val ,
        "outputs"                 AS outs                       -- JSON array
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp_month" >= '2023-07-01'
),                     /* explode outputs and capture each amount              */
out_vals AS (
    SELECT
        t.tx_hash ,
        t.month ,
        TRY_TO_NUMBER( (f.value:"value")::STRING ) AS out_val
    FROM tx t ,
         LATERAL FLATTEN ( INPUT => t.outs ) f
),                     /* flag tx that have ≥2 identical-value outputs         */
dup_flag AS (
    SELECT
        tx_hash ,
        CASE WHEN COUNT(*) > COUNT(DISTINCT out_val) THEN 1 ELSE 0 END AS has_dup
    FROM out_vals
    GROUP BY tx_hash
),                     /* classify CoinJoin transactions                       */
classified AS (
    SELECT
        t.month ,
        t.tx_hash ,
        t.input_cnt ,
        t.input_val ,
        CASE
            WHEN t.output_cnt > 2
             AND t.output_val <= t.input_val
             AND COALESCE(d.has_dup,0) = 1
            THEN 1 ELSE 0
        END AS is_coinjoin
    FROM tx t
    LEFT JOIN dup_flag d
           ON t.tx_hash = d.tx_hash
),                     /* monthly aggregation                                  */
monthly AS (
    SELECT
        month ,
        SUM(is_coinjoin)                                          AS cj_tx ,
        COUNT(*)                                                  AS all_tx ,
        SUM(CASE WHEN is_coinjoin=1 THEN input_cnt  ELSE 0 END)   AS cj_utxo ,
        SUM(input_cnt)                                            AS all_utxo ,
        SUM(CASE WHEN is_coinjoin=1 THEN input_val ELSE 0 END)    AS cj_vol ,
        SUM(input_val)                                            AS all_vol
    FROM classified
    GROUP BY month
)
SELECT
    month ,
    ROUND(100.0 * cj_tx   / NULLIF(all_tx  ,0), 4) AS pct_coinjoin_transactions ,
    ROUND(100.0 * cj_utxo / NULLIF(all_utxo,0), 4) AS pct_coinjoin_utxos       ,
    ROUND(100.0 * cj_vol  / NULLIF(all_vol ,0), 4) AS pct_coinjoin_volume
FROM monthly
ORDER BY month;