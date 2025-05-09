WITH tx AS (          -- Bitcoin transactions from July-2023 onward
    SELECT
        "hash",
        "block_timestamp_month"                         AS "month",
        "input_count",
        "output_count",
        "input_value"  ::FLOAT                          AS "input_value",
        "output_value" ::FLOAT                          AS "output_value",
        "outputs"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp_month" >= '2023-07-01'
),

/* explode outputs to examine individual amounts */
out_vals AS (
    SELECT
        t."hash",
        t."month",
        t."input_count",
        t."output_count",
        t."input_value",
        t."output_value",
        (f.value:"value")::FLOAT        AS out_val
    FROM tx t,
         LATERAL FLATTEN (input => t."outputs") f
),

/* aggregate back per-transaction & flag CoinJoins */
tx_aggr AS (
    SELECT
        "hash",
        "month",
        MAX("input_count")                         AS input_cnt,
        MAX("output_count")                        AS output_cnt,
        MAX("input_value")                         AS input_val,
        MAX("output_value")                        AS output_val,
        COUNT(*)                                   AS outputs_total,
        COUNT(DISTINCT out_val)                    AS outputs_distinct,
        CASE
             WHEN MAX("output_count") > 2
              AND MAX("output_value") <= MAX("input_value")
              AND COUNT(*) > COUNT(DISTINCT out_val)      -- ≥1 repeated value
             THEN 1 ELSE 0
        END                                        AS is_coinjoin
    FROM out_vals
    GROUP BY "hash","month"
),

/* monthly totals and CoinJoin subtotals */
monthly AS (
    SELECT
        "month",
        COUNT(*)                                   AS total_tx,
        SUM(is_coinjoin)                           AS cj_tx,
        SUM(input_cnt + output_cnt)                AS total_utxos,
        SUM( (input_cnt + output_cnt)*is_coinjoin) AS cj_utxos,
        SUM(input_val)                             AS total_vol,
        SUM(input_val*is_coinjoin)                 AS cj_vol
    FROM tx_aggr
    GROUP BY "month"
)

SELECT
    TO_CHAR("month",'YYYY-MM')                                    AS "month",
    ROUND(100 * cj_tx    / NULLIF(total_tx   ,0), 4) AS "pct_coinjoin_transactions",
    ROUND(100 * cj_utxos / NULLIF(total_utxos,0), 4) AS "pct_utxos_in_coinjoin",
    ROUND(100 * cj_vol   / NULLIF(total_vol  ,0), 4) AS "pct_volume_coinjoin"
FROM monthly
ORDER BY "month";