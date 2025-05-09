WITH tx AS (            -- All Bitcoin transactions in 2021
    SELECT
        "hash",
        "block_timestamp",
        "input_count"       ::NUMBER AS input_cnt,
        "output_count"      ::NUMBER AS output_cnt,
        TO_NUMBER("input_value")     AS in_val,
        TO_NUMBER("output_value")    AS out_val,
        "outputs"                     AS outs              -- keep VARIANT column
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp"
          BETWEEN 1609459200000000          -- 2021‑01‑01 00:00:00
              AND 1640995199000000          -- 2021‑12‑31 23:59:59
),                    
dup_check AS (        -- count distinct output values (satoshis) per tx
    SELECT
        t."hash",
        COUNT(DISTINCT TO_NUMBER(f.value:"value")) AS distinct_vals
    FROM tx t,
         LATERAL FLATTEN(INPUT => t.outs) f
    GROUP BY t."hash"
),                    
coinjoin AS (         -- CoinJoin definition
    SELECT t.*
    FROM   tx t
    JOIN   dup_check d  ON d."hash" = t."hash"
    WHERE  t.output_cnt > 2                 -- >2 outputs
      AND  t.out_val   <= t.in_val          -- no value inflation
      AND  d.distinct_vals < t.output_cnt   -- ≥1 repeated amount
),                    
cj_month AS (         -- CoinJoin totals by month
    SELECT
        EXTRACT(month FROM TO_TIMESTAMP_NTZ("block_timestamp"/1e6)) AS mth,
        COUNT(*)                AS cj_tx,
        SUM(input_cnt)          AS cj_inputs,
        SUM(output_cnt)         AS cj_outputs,
        SUM(out_val)            AS cj_val
    FROM coinjoin
    GROUP BY mth
),                    
all_month AS (        -- Totals for all txs by month
    SELECT
        EXTRACT(month FROM TO_TIMESTAMP_NTZ("block_timestamp"/1e6)) AS mth,
        COUNT(*)                AS tot_tx,
        SUM(input_cnt)          AS tot_inputs,
        SUM(output_cnt)         AS tot_outputs,
        SUM(out_val)            AS tot_val
    FROM tx
    GROUP BY mth
),                    
metrics AS (          -- Percentages
    SELECT
        a.mth                                                     AS month,
        ROUND(100.0 * c.cj_tx     / a.tot_tx    , 1)              AS pct_tx,
        ROUND( ( (100.0 * c.cj_inputs  / a.tot_inputs) +
                 (100.0 * c.cj_outputs / a.tot_outputs) ) / 2 , 1) AS pct_utxos,
        ROUND(100.0 * c.cj_val    / a.tot_val   , 1)              AS pct_volume
    FROM cj_month c
    JOIN all_month a USING (mth)
)
SELECT
    month,          -- month (1‑12)
    pct_tx,         -- % of all txs that are CoinJoin
    pct_utxos,      -- % of UTXOs involved (avg in/out)
    pct_volume      -- % of BTC volume in CoinJoin
FROM metrics
ORDER BY pct_volume DESC NULLS LAST
LIMIT 1;