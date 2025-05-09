/*  Monthly CoinJoin percentages for Bitcoin (from 1-Jul-2023)  */
WITH candidate_dupes AS (        -- every output of every tx ≥ 2023-07-01
    SELECT
        t."hash"                              AS tx_hash,
        f.value:"value"::NUMBER               AS out_value
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS t
         ,LATERAL FLATTEN(input => t."outputs") f
    WHERE t."block_timestamp" >= 1688169600000000   -- 2023-07-01 00:00 UTC (µs)
),
dupe_value_tx AS (               -- txs that have ≥2 identical-value outputs
    SELECT  tx_hash
    FROM    candidate_dupes
    GROUP BY tx_hash, out_value
    HAVING  COUNT(*) > 1
),
all_txs AS (                      -- basic data for every tx in scope
    SELECT
        "hash"                                 AS tx_hash,
        "block_timestamp",
        ARRAY_SIZE("inputs")                   AS n_inputs,
        ARRAY_SIZE("outputs")                  AS n_outputs,
        "input_value" :: NUMBER                AS in_value,
        "output_value":: NUMBER                AS out_value
    FROM   CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE  "block_timestamp" >= 1688169600000000
),
coinjoin AS (                     -- CoinJoin-candidate definition
    SELECT *
    FROM   all_txs
    WHERE  n_outputs > 2
      AND  out_value <= in_value
      AND  tx_hash IN (SELECT tx_hash FROM dupe_value_tx)
),
cj_month AS (                     -- monthly totals for CoinJoin candidates
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ("block_timestamp"/1e6),'YYYY-MM') AS month,
        COUNT(*)                                                   AS cj_tx_cnt,
        SUM(n_inputs)                                              AS cj_utxos,
        SUM(in_value)                                              AS cj_volume
    FROM   coinjoin
    GROUP  BY 1
),
total_month AS (                  -- monthly totals for all Bitcoin txs
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ("block_timestamp"/1e6),'YYYY-MM') AS month,
        COUNT(*)                                                   AS all_tx_cnt,
        SUM(n_inputs)                                              AS all_utxos,
        SUM(in_value)                                              AS all_volume
    FROM   all_txs
    GROUP  BY 1
)
SELECT
    t.month,
    ROUND(cj.cj_tx_cnt / NULLIF(t.all_tx_cnt ,0), 6) AS tx_pct_coinjoin,
    ROUND(cj.cj_utxos  / NULLIF(t.all_utxos ,0), 6)  AS utxo_pct_coinjoin,
    ROUND(cj.cj_volume / NULLIF(t.all_volume,0), 6)  AS volume_pct_coinjoin
FROM       total_month  t
LEFT JOIN  cj_month     cj USING (month)
ORDER BY   t.month;