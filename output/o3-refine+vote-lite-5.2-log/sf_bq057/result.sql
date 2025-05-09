WITH tx AS (   -- all 2021 BTC transactions
    SELECT
        "hash",
        "block_timestamp",
        "input_value"::FLOAT      AS input_value,
        "output_value"::FLOAT     AS output_value,
        "input_count"::INT        AS input_cnt,
        "output_count"::INT       AS output_cnt,
        "outputs"                 AS outs,            -- VARIANT
        TO_TIMESTAMP_NTZ("block_timestamp"/1e6)       AS ts
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" >= 1609459200000000      -- 2021‑01‑01
      AND "block_timestamp" < 1640995200000000       -- 2022‑01‑01
),  
outputs_flat AS (   -- explode outputs
    SELECT
        t."hash",
        (o.value:"value")::FLOAT AS out_val
    FROM tx t,
         LATERAL FLATTEN(INPUT => PARSE_JSON(t.outs)) o
),  
dup_tx AS (          -- txs having ≥2 identical‑value outputs
    SELECT
        "hash",
        CASE WHEN COUNT(*) > COUNT(DISTINCT out_val) THEN 1 ELSE 0 END AS has_dup
    FROM outputs_flat
    GROUP BY "hash"
),  
coinjoin_flag AS (
    SELECT
        t.*,
        COALESCE(d.has_dup,0) AS has_dup
    FROM tx t
    LEFT JOIN dup_tx d USING("hash")
),  
coinjoin_tx AS (     -- mark CoinJoin txs
    SELECT
        *,
        DATE_PART(month, ts) AS month,
        CASE
             WHEN output_cnt > 2
              AND has_dup = 1
              AND output_value <= input_value
             THEN 1 ELSE 0
        END AS is_coinjoin
    FROM coinjoin_flag
),  
month_stats AS (     -- monthly aggregates
    SELECT
        month,
        COUNT(*)                                       AS total_tx,
        SUM(is_coinjoin)                               AS coinjoin_tx,
        SUM(input_cnt)                                 AS total_inputs,
        SUM(output_cnt)                                AS total_outputs,
        SUM(CASE WHEN is_coinjoin=1 THEN input_cnt  END) AS cj_inputs,
        SUM(CASE WHEN is_coinjoin=1 THEN output_cnt END) AS cj_outputs,
        SUM(output_value)                              AS total_vol,
        SUM(CASE WHEN is_coinjoin=1 THEN output_value END) AS cj_vol
    FROM coinjoin_tx
    GROUP BY month
),  
ranked AS (          -- compute percentages & rank
    SELECT
        month,
        ROUND(coinjoin_tx*100.0/NULLIF(total_tx,0),1)                               AS pct_tx,
        ROUND(((cj_inputs*100.0/NULLIF(total_inputs,0)) +
               (cj_outputs*100.0/NULLIF(total_outputs,0)))/2 ,1)                   AS pct_utxo,
        ROUND(cj_vol*100.0/NULLIF(total_vol,0),1)                                   AS pct_vol,
        ROW_NUMBER() OVER (ORDER BY cj_vol/NULLIF(total_vol,0) DESC)                AS rn
    FROM month_stats
)  
SELECT
    month                                        AS "month",
    pct_tx                                       AS "pct_coinjoin_transactions",
    pct_utxo                                     AS "pct_utxos_in_coinjoin",
    pct_vol                                      AS "pct_volume_in_coinjoin"
FROM ranked
WHERE rn = 1;