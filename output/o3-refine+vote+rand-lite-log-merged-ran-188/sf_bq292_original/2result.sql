WITH tx AS (   -- non‑coinbase transactions from 2023‑07‑01 onward
    SELECT
        "hash",
        "block_timestamp",
        "input_count",
        "output_count",
        "input_value"  :: FLOAT AS input_value,
        "output_value" :: FLOAT AS output_value,
        "outputs",
        "block_timestamp" / 1000000 AS ts_sec                -- µs → s
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" >= 1688169600000000              -- 2023‑07‑01
      AND "is_coinbase" = FALSE
),
dup_vals AS (   -- outputs per tx and distinct output amounts
    SELECT
        t."hash",
        COUNT(*)                                              AS tot_outs,
        COUNT(DISTINCT ((f.value:"value")::FLOAT))            AS distinct_vals
    FROM tx t,
         LATERAL FLATTEN(INPUT => t."outputs") f
    GROUP BY t."hash"
),
flagged AS (    -- identify CoinJoin transactions
    SELECT
        t.*,
        CASE
            WHEN t."output_count" > 2
             AND t.output_value <= t.input_value
             AND d.tot_outs > d.distinct_vals
            THEN 1 ELSE 0
        END AS is_coinjoin
    FROM tx t
    JOIN dup_vals d ON t."hash" = d."hash"
),
mth AS (        -- monthly aggregates
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(ts_sec), 'YYYY-MM')                             AS month,
        COUNT(*)                                                                 AS total_tx,
        SUM(is_coinjoin)                                                         AS cj_tx,
        SUM("input_count")                                                       AS tot_inputs,
        SUM("output_count")                                                      AS tot_outputs,
        SUM(CASE WHEN is_coinjoin = 1 THEN "input_count"  END)                   AS cj_inputs,
        SUM(CASE WHEN is_coinjoin = 1 THEN "output_count" END)                   AS cj_outputs,
        SUM(input_value)                                                         AS tot_in_val,
        SUM(CASE WHEN is_coinjoin = 1 THEN input_value END)                      AS cj_in_val
    FROM flagged
    GROUP BY month
)
SELECT
    month,
    ROUND(100.0 * cj_tx     / NULLIF(total_tx ,0), 4)                                            AS "PCT_COINJOIN_TX",
    ROUND(50.0 * ( cj_inputs / NULLIF(tot_inputs ,0)
                 + cj_outputs/ NULLIF(tot_outputs,0) ), 4)                                       AS "PCT_UTXOS_IN_COINJOIN",
    ROUND(100.0 * cj_in_val / NULLIF(tot_in_val,0), 4)                                           AS "PCT_VOLUME_IN_COINJOIN"
FROM mth
ORDER BY month;