WITH tx2021 AS (   -- all 2021 bitcoin transactions
    SELECT
        "hash",
        "outputs",
        "input_value" :: NUMBER                      AS input_val,
        "output_value":: NUMBER                      AS output_val,
        "input_count" :: NUMBER                      AS in_cnt,
        "output_count":: NUMBER                      AS out_cnt,
        TO_NUMBER(
            TO_CHAR(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6),'MM')
        )                                            AS mth        -- month number (1-12)
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp"
          BETWEEN 1609459200000000 /* 2021-01-01 */
              AND 1640995199000000 /* 2021-12-31 */
),                                                   -- tx that have ≥2 identical output values
dup_hashes AS (
    SELECT DISTINCT "hash"
    FROM (
        SELECT
            t."hash",
            f.value:"value" :: NUMBER AS out_val
        FROM tx2021 t,
             LATERAL FLATTEN (INPUT => t."outputs") f
    )
    GROUP BY "hash", out_val
    HAVING COUNT(*) > 1
),                                                   -- CoinJoin definition
coinjoin_tx AS (
    SELECT *
    FROM tx2021
    WHERE out_cnt > 2
      AND output_val <= input_val
      AND "hash" IN (SELECT "hash" FROM dup_hashes)
),                                                   -- monthly totals
monthly_totals AS (
    SELECT
        mth                                          AS month,
        COUNT(*)                                     AS total_tx,
        SUM(in_cnt)                                  AS total_in_utxo,
        SUM(out_cnt)                                 AS total_out_utxo,
        SUM(input_val)                               AS total_vol
    FROM tx2021
    GROUP BY mth
),                                                   -- monthly CoinJoin subtotals
cj_monthly AS (
    SELECT
        mth                                          AS month,
        COUNT(*)                                     AS cj_tx,
        SUM(in_cnt)                                  AS cj_in_utxo,
        SUM(out_cnt)                                 AS cj_out_utxo,
        SUM(input_val)                               AS cj_vol
    FROM coinjoin_tx
    GROUP BY mth
),                                                   -- combine & compute percentages
joined AS (
    SELECT
        t.month,
        100.0 * c.cj_tx       / NULLIF(t.total_tx      ,0)                          AS tx_pct,
        (100.0 * c.cj_in_utxo / NULLIF(t.total_in_utxo ,0) +
         100.0 * c.cj_out_utxo/ NULLIF(t.total_out_utxo,0)) / 2                     AS utxo_pct,
        100.0 * c.cj_vol      / NULLIF(t.total_vol     ,0)                          AS vol_pct
    FROM monthly_totals t
    JOIN cj_monthly   c  USING (month)
)
SELECT
    month                                            AS "month",
    ROUND(tx_pct ,1)                                 AS "pct_tx_coinjoin",
    ROUND(utxo_pct,1)                                AS "pct_utxos_coinjoin",
    ROUND(vol_pct ,1)                                AS "pct_volume_coinjoin"
FROM joined
ORDER BY vol_pct DESC NULLS LAST                     -- month with highest volume %
LIMIT 1;