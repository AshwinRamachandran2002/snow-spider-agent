WITH btc_tx_2021 AS (   -- Bitcoin transactions from 2021 (timestamps stored in µs)
    SELECT
        "hash"                                        AS tx_hash,
        "block_timestamp"                             AS ts_us,
        EXTRACT(month FROM TO_TIMESTAMP_NTZ("block_timestamp"/1e6))  AS month_num,
        "output_count"                                AS out_cnt,
        "input_count"                                 AS in_cnt,
        "output_value"::FLOAT                         AS out_value,
        "input_value"::FLOAT                          AS in_value,
        "outputs"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE EXTRACT(year FROM TO_TIMESTAMP_NTZ("block_timestamp"/1e6)) = 2021
          AND "output_count" > 2          -- CoinJoin requires > 2 outputs
), ------------------------------------------------------------------
dup_outputs AS (                  -- detect duplicate (equal‑value) outputs
    SELECT
        t.tx_hash,
        COUNT(*)  AS tot_outs,
        COUNT(DISTINCT TRY_TO_DECIMAL( (f.value:"value")::STRING )) AS distinct_vals
    FROM btc_tx_2021 t,
         LATERAL FLATTEN(input => t."outputs") f
    GROUP BY t.tx_hash
), ------------------------------------------------------------------
coinjoin_flags AS (               -- flag txs that have ≥2 identical outputs
    SELECT
        tx_hash,
        CASE WHEN tot_outs > distinct_vals THEN 1 ELSE 0 END AS has_dup_outs
    FROM dup_outputs
), ------------------------------------------------------------------
tx_labeled AS (                   -- mark each tx CoinJoin (1) / non‑CoinJoin (0)
    SELECT
        t.month_num,
        t.tx_hash,
        t.in_cnt,
        t.out_cnt,
        t.in_value,
        t.out_value,
        CASE
            WHEN t.out_value <= t.in_value              -- spends ≤ inputs
             AND cf.has_dup_outs = 1                    -- duplicate outputs
            THEN 1 ELSE 0
        END                                            AS is_coinjoin
    FROM btc_tx_2021 t
    LEFT JOIN coinjoin_flags cf
           ON t.tx_hash = cf.tx_hash
), ------------------------------------------------------------------
monthly_stats AS (
    SELECT
        month_num,
        SUM(is_coinjoin)                                       AS cj_tx,
        COUNT(*)                                               AS all_tx,
        SUM(CASE WHEN is_coinjoin = 1 THEN in_cnt  END)        AS cj_inputs,
        SUM(in_cnt)                                            AS all_inputs,
        SUM(CASE WHEN is_coinjoin = 1 THEN out_cnt END)        AS cj_outputs,
        SUM(out_cnt)                                           AS all_outputs,
        SUM(CASE WHEN is_coinjoin = 1 THEN out_value END)      AS cj_vol,
        SUM(out_value)                                         AS all_vol
    FROM tx_labeled
    GROUP BY month_num
), ------------------------------------------------------------------
monthly_pct AS (
    SELECT
        month_num,
        ROUND(100.0 * cj_tx     / NULLIF(all_tx    ,0), 1)                         AS pct_tx,
        ROUND(100.0 * ( (cj_inputs / NULLIF(all_inputs ,0)) +
                        (cj_outputs/ NULLIF(all_outputs,0)) ) / 2 , 1)             AS pct_utxo,
        ROUND(100.0 * cj_vol    / NULLIF(all_vol   ,0), 1)                         AS pct_vol
    FROM monthly_stats
), ------------------------------------------------------------------
best_month AS (                    -- month with highest CoinJoin volume share
    SELECT *
    FROM   monthly_pct
    ORDER  BY pct_vol DESC NULLS LAST, month_num
    LIMIT  1
)
SELECT
    month_num   AS "MONTH",
    pct_tx      AS "PERCENT_TX_COINJOIN",
    pct_utxo    AS "PERCENT_UTXO_COINJOIN",
    pct_vol     AS "PERCENT_VOLUME_COINJOIN"
FROM best_month;