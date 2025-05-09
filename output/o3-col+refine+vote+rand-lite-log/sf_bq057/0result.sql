WITH tx_2021 AS (          -- all 2021 Bitcoin transactions
    SELECT  "hash",
            "block_timestamp",
            "input_count",
            "output_count",
            "input_value",
            "output_value",
            DATE_TRUNC('month', TO_TIMESTAMP_NTZ("block_timestamp"/1e6)) AS "mth"
    FROM    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE   "block_timestamp" BETWEEN 1609459200000000   -- 2021-01-01
                                  AND 1640995199000000   -- 2021-12-31
),
/* ------------------------------------------------------------------ *
 * CoinJoin proxy-definition:  >2 outputs and total output ≤ inputs   *
 * ------------------------------------------------------------------ */
coinjoin_tx AS (
    SELECT *
    FROM   tx_2021
    WHERE  "output_count" > 2
      AND  "output_value" <= "input_value"
),
/* -------- monthly totals (all tx) ---------- */
all_month AS (
    SELECT  "mth",
            COUNT(*)                 AS all_tx,
            SUM("input_count")       AS all_inputs,
            SUM("output_count")      AS all_outputs,
            SUM("output_value")      AS all_vol
    FROM    tx_2021
    GROUP  BY 1
),
/* -------- monthly CoinJoin totals ---------- */
cj_month AS (
    SELECT  "mth",
            COUNT(*)                 AS cj_tx,
            SUM("input_count")       AS cj_inputs,
            SUM("output_count")      AS cj_outputs,
            SUM("output_value")      AS cj_vol
    FROM    coinjoin_tx
    GROUP  BY 1
),
/* -------- percentages per month ------------ */
pct AS (
    SELECT  a."mth",
            ROUND(100.0 * cj.cj_tx      / a.all_tx       ,1)               AS pct_txn,
            ROUND(
                  100.0 * ( (cj.cj_inputs / a.all_inputs)
                          + (cj.cj_outputs/ a.all_outputs) ) / 2 ,1)       AS pct_utxo,
            ROUND(100.0 * cj.cj_vol     / a.all_vol      ,1)               AS pct_volume
    FROM    all_month a
    JOIN    cj_month cj USING ("mth")
)
SELECT  EXTRACT(month FROM "mth")                 AS "month_in_2021",
        pct_txn                                   AS "pct_coinjoin_txns",
        pct_utxo                                  AS "pct_utxos_in_coinjoin",
        pct_volume                                AS "pct_volume_in_coinjoin"
FROM    pct
ORDER BY pct_volume DESC NULLS LAST
LIMIT 1;