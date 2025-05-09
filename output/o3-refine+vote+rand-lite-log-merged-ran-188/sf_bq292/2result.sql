/* -----------------------------------------------------------
   Monthly share of CoinJoin activity on Bitcoin (since 2023-07)
   – CoinJoin definition
       1. ≥ 3 identical-value outputs
       2. > 2 total outputs
       3. Σ(output value) ≤ Σ(input value)
   – Percentages returned for:
       • transactions          (count)
       • UTXOs touched         (inputs + outputs)
       • transferred volume    (input value)
-------------------------------------------------------------*/
WITH
params AS (  -- 2023-07-01 00:00:00 UTC  in μs
  SELECT 1688169600000000::NUMBER AS cutoff_ts
),

/* 1) Transactions that contain at least three outputs
      having the exact same value */
repeated_hashes AS (
  SELECT DISTINCT tx_hash
  FROM (
        SELECT
          t."hash"        AS tx_hash,
          f.value:"value"::NUMBER AS out_value
        FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS t
        JOIN params p
          ON t."block_timestamp" >= p.cutoff_ts
        ,  LATERAL FLATTEN (INPUT => t."outputs") f
  )
  GROUP BY tx_hash, out_value
  HAVING COUNT(*) >= 3            -- “multiple identical-value outputs”
),

/* 2) CoinJoin transactions (apply all three rules) */
coinjoin_tx AS (
  SELECT
    t."hash",
    t."block_timestamp",
    TO_CHAR(TO_TIMESTAMP(t."block_timestamp" / 1e6), 'YYYY-MM')              AS "month",
    t."input_count" ::NUMBER                                                AS in_cnt,
    t."output_count"::NUMBER                                                AS out_cnt,
    t."input_value" ::NUMBER                                                AS in_val,
    t."output_value"::NUMBER                                                AS out_val
  FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS t
  JOIN repeated_hashes r  ON r.tx_hash = t."hash"
  JOIN params          p  ON t."block_timestamp" >= p.cutoff_ts
  WHERE t."output_count" > 2
    AND t."output_value"::NUMBER <= t."input_value"::NUMBER
),

/* 3) Monthly aggregates for CoinJoin activity */
agg_coinjoin AS (
  SELECT
    "month",
    COUNT(*)                                    AS cj_tx_cnt,
    SUM(in_cnt + out_cnt)                       AS cj_utxos,
    SUM(in_val)                                 AS cj_volume
  FROM coinjoin_tx
  GROUP BY "month"
),

/* 4) Monthly aggregates for the whole network */
agg_total AS (
  SELECT
    TO_CHAR(TO_TIMESTAMP(t."block_timestamp" / 1e6), 'YYYY-MM')              AS "month",
    COUNT(*)                                        AS all_tx_cnt,
    SUM(t."input_count"::NUMBER + t."output_count"::NUMBER) AS all_utxos,
    SUM(t."input_value"::NUMBER)                    AS all_volume
  FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS t
  JOIN params p  ON t."block_timestamp" >= p.cutoff_ts
  GROUP BY "month"
)

/* 5) Final percentages */
SELECT
  a."month",
  ROUND(COALESCE(c.cj_tx_cnt ,0) / a.all_tx_cnt  * 100 , 4) AS pct_coinjoin_transactions,
  ROUND(COALESCE(c.cj_utxos ,0) / a.all_utxos  * 100 , 4)   AS pct_coinjoin_utxos,
  ROUND(COALESCE(c.cj_volume,0) / a.all_volume * 100 , 4)   AS pct_coinjoin_volume
FROM  agg_total  a
LEFT  JOIN agg_coinjoin c  ON a."month" = c."month"
ORDER BY a."month";