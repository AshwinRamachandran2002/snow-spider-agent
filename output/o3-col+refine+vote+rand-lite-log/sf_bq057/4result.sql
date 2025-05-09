WITH btc_tx_2021 AS (   -- every 2021 BTC tx
    SELECT  "hash",
            "input_count",
            "output_count",
            "input_value",
            "output_value",
            "outputs",
            MONTH(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS mn
    FROM    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE   YEAR(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) = 2021
),

/* -----------------------------------------------------------
   1) For each tx, find the biggest multiplicity of any output
      value (to spot equal-value outputs).
   ----------------------------------------------------------- */
tx_equal_outs AS (
    SELECT  sub."hash",
            MAX(sub.cnt_same_val) AS max_equal_outs
    FROM   (
            SELECT  t."hash",
                    (o.value:"value"::STRING)         AS out_val,
                    COUNT(*)                          AS cnt_same_val
            FROM    btc_tx_2021      t,
                    LATERAL FLATTEN(input => t."outputs") o
            GROUP BY t."hash", out_val
          ) sub
    GROUP BY sub."hash"
),

/* -----------------------------------------------------------
   2)  CoinJoin definition filter
   ----------------------------------------------------------- */
coinjoin_tx AS (
    SELECT  b.*
    FROM    btc_tx_2021  b
    JOIN    tx_equal_outs e  ON e."hash" = b."hash"
    WHERE   b."output_count"  > 2                 -- many outputs
      AND   b."output_value" <= b."input_value"   -- no value gain
      AND   e.max_equal_outs  >= 2                -- ≥2 equal outputs
),

/* -----------------------------------------------------------
   3) monthly aggregates for all vs CoinJoin
   ----------------------------------------------------------- */
all_monthly AS (
    SELECT  mn,
            COUNT(*)                       AS tot_txns,
            SUM("input_count")            AS tot_inputs,
            SUM("output_count")           AS tot_outputs,
            SUM("output_value")           AS tot_vol
    FROM   btc_tx_2021
    GROUP  BY mn
),
cj_monthly AS (
    SELECT  mn,
            COUNT(*)                       AS cj_txns,
            SUM("input_count")            AS cj_inputs,
            SUM("output_count")           AS cj_outputs,
            SUM("output_value")           AS cj_vol
    FROM   coinjoin_tx
    GROUP  BY mn
),

/* -----------------------------------------------------------
   4) percentages (guarding against divide-by-zero)
   ----------------------------------------------------------- */
pct AS (
    SELECT  a.mn                                                  AS month_num,
            100.0 * c.cj_txns   / NULLIF(a.tot_txns  ,0)         AS pct_txns,
            50.0 * ( 100.0 * c.cj_inputs  / NULLIF(a.tot_inputs ,0)
                    + 100.0 * c.cj_outputs / NULLIF(a.tot_outputs,0) )   AS pct_utxos,
            100.0 * c.cj_vol    / NULLIF(a.tot_vol   ,0)         AS pct_vol
    FROM    all_monthly  a
    JOIN    cj_monthly   c USING (mn)
)

/* -----------------------------------------------------------
   5) month with highest CoinJoin volume share
   ----------------------------------------------------------- */
SELECT  month_num                                   AS "month",
        ROUND(pct_txns ,1)                          AS "pct_coinjoin_txns",
        ROUND(pct_utxos,1)                          AS "pct_coinjoin_utxos",
        ROUND(pct_vol  ,1)                          AS "pct_coinjoin_volume"
FROM    pct
ORDER BY pct_vol DESC NULLS LAST
LIMIT 1;