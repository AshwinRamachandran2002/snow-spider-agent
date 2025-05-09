WITH tx AS (
    SELECT
        "hash",
        "input_count",
        "output_count",
        /* columns are already numeric, just cast to FLOAT for uniformity */
        CAST("input_value"  AS FLOAT)               AS input_val,
        CAST("output_value" AS FLOAT)               AS output_val,
        "outputs"                                    AS outs,
        MONTH( TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) ) AS mth
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE YEAR( TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) ) = 2021
),
/* explode outputs to get each output’s value */
out_vals AS (
    SELECT
        t."hash",
        TRY_TO_NUMBER( f.value:"value"::STRING )    AS out_val
    FROM tx t,
         LATERAL FLATTEN(INPUT => t.outs) f
),
/* number of outputs and number of distinct‑valued outputs per tx */
agg AS (
    SELECT
        "hash",
        COUNT(*)                    AS n_outs,
        COUNT(DISTINCT out_val)     AS n_distinct
    FROM out_vals
    GROUP BY "hash"
),
/* identify CoinJoin transactions */
coinjoin AS (
    SELECT
        t.*,
        CASE
             WHEN t."output_count" > 2
              AND t.output_val <= t.input_val                      -- no new coins
              AND a.n_distinct < t."output_count"                  -- at least two equal‑value outputs
             THEN 1 ELSE 0
        END AS is_cj
    FROM tx  t
    JOIN agg a ON t."hash" = a."hash"
),
/* monthly aggregates */
mon AS (
    SELECT
        mth                                                 AS month,
        SUM(is_cj)                                          AS cj_tx,
        COUNT(*)                                            AS tot_tx,
        SUM(CASE WHEN is_cj = 1 THEN "input_count"  END)    AS cj_ins,
        SUM("input_count")                                  AS tot_ins,
        SUM(CASE WHEN is_cj = 1 THEN "output_count" END)    AS cj_outs,
        SUM("output_count")                                 AS tot_outs,
        SUM(CASE WHEN is_cj = 1 THEN output_val END)        AS cj_vol,
        SUM(output_val)                                     AS tot_vol
    FROM coinjoin
    GROUP BY month
),
/* convert to percentages */
metrics AS (
    SELECT
        month,
        ROUND( 100.0 * cj_tx  / NULLIF(tot_tx , 0), 1)                          AS pct_tx,
        ROUND( ( 100.0 * cj_ins / NULLIF(tot_ins ,0)
               + 100.0 * cj_outs/ NULLIF(tot_outs,0) ) / 2 , 1)                AS pct_utxos,
        ROUND( 100.0 * cj_vol / NULLIF(tot_vol, 0), 1)                          AS pct_vol
    FROM mon
)
SELECT
    month,
    pct_tx      AS "pct_coinjoin_transactions",
    pct_utxos   AS "pct_utxos_in_coinjoin",
    pct_vol     AS "pct_volume_in_coinjoin"
FROM metrics
ORDER BY pct_vol DESC NULLS LAST, month
LIMIT 1;