/*  Monthly CoinJoin statistics on the Bitcoin network – July-2023 onward  */
WITH btc_tx AS (          -- 1. base set (since 1-Jul-2023)
    SELECT  "hash",
            "block_timestamp",
            "input_count",
            "output_count",
            "input_value",
            "output_value",
            "outputs"
    FROM    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE   "block_timestamp" >= 1688169600000000        -- 2023-07-01 in µs
),

/* 2. split every output to discover duplicates (same value shown >1 time) */
outputs_flat AS (
    SELECT  t."hash",
            (flt.value:"value")::FLOAT      AS out_val           -- individual value
    FROM    btc_tx      t,
            LATERAL FLATTEN(input => t."outputs") flt
),

dup_info AS (            -- 3. count distinct vs total outputs per tx
    SELECT  "hash",
            COUNT(*)                      AS out_cnt,
            COUNT(DISTINCT out_val)       AS distinct_val_cnt
    FROM    outputs_flat
    GROUP BY "hash"
),

/* 4. add the duplicate information & classify CoinJoin transactions      */
classified AS (
    SELECT  t.*,
            CASE WHEN t."output_count" > 2
                      AND t."output_value" <= t."input_value"
                      AND d.distinct_val_cnt < t."output_count"
                 THEN 1 ELSE 0 END        AS is_coinjoin
    FROM    btc_tx  t
    JOIN    dup_info d  USING ("hash")
),

/* 5. reshape to daily rows for later monthly aggregation                 */
daily AS (
    SELECT  DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp"/1e6)) AS day,
            is_coinjoin,
            ("input_count" + "output_count")                       AS utxos,
            "input_value"                                          AS volume
    FROM    classified
),

/* 6. monthly aggregation of totals vs CoinJoin subsets                  */
monthly AS (
    SELECT  DATE_TRUNC('month', day)                              AS month,
            SUM(CASE WHEN is_coinjoin=1 THEN 1 ELSE 0 END)        AS cj_tx,
            COUNT(*)                                              AS all_tx,
            SUM(CASE WHEN is_coinjoin=1 THEN utxos ELSE 0 END)    AS cj_utxos,
            SUM(utxos)                                            AS all_utxos,
            SUM(CASE WHEN is_coinjoin=1 THEN volume ELSE 0 END)   AS cj_vol,
            SUM(volume)                                           AS all_vol
    FROM    daily
    GROUP BY month
)

/* 7. final percentage metrics                                            */
SELECT  month,
        ROUND(100.0 * cj_tx    / all_tx   , 4)   AS "pct_coinjoin_transactions",
        ROUND(100.0 * cj_utxos / all_utxos, 4)   AS "pct_coinjoin_utxos",
        ROUND(100.0 * cj_vol   / all_vol  , 4)   AS "pct_coinjoin_volume"
FROM    monthly
ORDER BY month;