WITH btc_tx AS (   -- Bitcoin transactions from July‑2023 onward
    SELECT
        "hash",
        "outputs",
        "input_count",
        "output_count",
        "input_value" :: FLOAT  AS "input_value",
        "output_value":: FLOAT  AS "output_value",
        ("input_count" + "output_count")          AS "utxos_in_tx",
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP("block_timestamp" / 1e6) -- micro‑secs → ts
        )                                         AS "month"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" >= 1688169600000000   -- 2023‑07‑01 00:00:00 UTC
),

/* flatten every output to detect identical‑value outputs */
tx_outputs AS (
    SELECT
        t."hash",
        f.value:"value" :: FLOAT  AS "out_val"
    FROM btc_tx t,
         LATERAL FLATTEN ( INPUT => t."outputs" ) f
),

output_stats AS (     -- per‑tx duplicate‑value test
    SELECT
        "hash",
        COUNT(*)                 AS "total_outs",
        COUNT(DISTINCT "out_val") AS "distinct_out_vals"
    FROM tx_outputs
    GROUP BY "hash"
),

classified AS (       -- tag CoinJoin transactions
    SELECT
        t.*,
        CASE
            WHEN t."output_count" > 2
             AND t."output_value" <= t."input_value"
             AND os."distinct_out_vals" < os."total_outs"   -- duplicate values
            THEN 1 ELSE 0
        END AS "is_coinjoin"
    FROM btc_tx t
    JOIN output_stats os
      ON t."hash" = os."hash"
),

monthly AS (          -- monthly aggregates
    SELECT
        "month",
        COUNT(*)                                    AS "total_txs",
        SUM("is_coinjoin")                          AS "cj_txs",
        SUM("utxos_in_tx")                          AS "total_utxos",
        SUM(CASE WHEN "is_coinjoin"=1 THEN "utxos_in_tx" END) AS "cj_utxos",
        SUM("input_value")                          AS "total_vol",
        SUM(CASE WHEN "is_coinjoin"=1 THEN "input_value" END) AS "cj_vol"
    FROM classified
    GROUP BY "month"
)

SELECT
    "month",
    ROUND( ("cj_txs"   * 100.0) / NULLIF("total_txs" ,0), 4) AS "pct_coinjoin_transactions",
    ROUND( ("cj_utxos" * 100.0) / NULLIF("total_utxos",0), 4) AS "pct_coinjoin_utxos",
    ROUND( ("cj_vol"   * 100.0) / NULLIF("total_vol" ,0), 4) AS "pct_coinjoin_volume"
FROM monthly
ORDER BY "month" ASC;