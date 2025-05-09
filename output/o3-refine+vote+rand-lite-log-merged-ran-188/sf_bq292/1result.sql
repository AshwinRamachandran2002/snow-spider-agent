/* Monthly CoinJoin share in the Bitcoin network since 2023-07-01        */
WITH tx_data AS (                    -- restrict universe to the period
    SELECT
        t."hash",
        t."block_timestamp",
        t."input_value",
        t."output_value",
        t."input_count",
        t."output_count",
        t."outputs"                                  -- needed later
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS t
    WHERE t."block_timestamp" >= 1688169600000000    -- 2023-07-01 (µs-epoch)
),

/* 1. Duplicate-denomination test on every tx’s outputs                   */
dup_outputs AS (
    SELECT
        t."hash",
        COUNT(*)                                                   AS out_cnt,
        COUNT(DISTINCT (o.value::VARIANT:"value")::NUMBER)         AS distinct_out_vals_cnt
    FROM tx_data t,
         LATERAL FLATTEN(input => t."outputs") o
    GROUP BY t."hash"
),

/* 2. Final CoinJoin list applying all three criteria                    */
coinjoin_list AS (
    SELECT d."hash"
    FROM   dup_outputs d
    JOIN   tx_data     t  ON t."hash" = d."hash"
    WHERE  t."output_count" > 2
      AND  t."output_value" <= t."input_value"
      AND  d.out_cnt > d.distinct_out_vals_cnt                      -- duplicates exist
),

/* 3. Network-wide monthly aggregates                                    */
all_stats AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP("block_timestamp"/1e6),'YYYY-MM') AS yyyymm,
        COUNT(*)                           AS tx_cnt,
        SUM("input_count")                 AS utxo_all,
        SUM("input_value")                 AS vol_all
    FROM tx_data
    GROUP BY 1
),

/* 4. CoinJoin-only monthly aggregates                                   */
cj_stats AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP(t."block_timestamp"/1e6),'YYYY-MM') AS yyyymm,
        COUNT(*)                         AS cj_tx_cnt,
        SUM(t."input_count")             AS cj_utxos,
        SUM(t."input_value")             AS cj_vol
    FROM tx_data        t
    JOIN coinjoin_list  c ON t."hash" = c."hash"
    GROUP BY 1
)

/* 5. Percentage contribution of CoinJoins per metric                    */
SELECT
    a.yyyymm                                                AS "month",
    ROUND(cj.cj_tx_cnt ::FLOAT / a.tx_cnt   , 6)            AS "pct_transactions",
    ROUND(cj.cj_utxos  ::FLOAT / a.utxo_all, 6)             AS "pct_utxos",
    ROUND(cj.cj_vol    ::FLOAT / a.vol_all ,12)             AS "pct_volume"
FROM all_stats a
LEFT JOIN cj_stats cj
       ON a.yyyymm = cj.yyyymm
ORDER BY a.yyyymm;