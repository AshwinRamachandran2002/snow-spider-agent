WITH
/* ---------------- 2021 Bitcoin transactions ---------------- */
tx_2021 AS (
    SELECT  "hash",
            "block_timestamp",
            "output_count",
            "input_value",
            "output_value"
    FROM    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE   TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp"/1e6))
            BETWEEN '2021-01-01' AND '2021-12-31'
),
/* ---------------- transactions that have ≥2 identical‑value outputs ---------------- */
equal_val_tx AS (
    SELECT DISTINCT "transaction_hash"
    FROM (
        SELECT  "transaction_hash"
        FROM    CRYPTO.CRYPTO_BITCOIN.OUTPUTS
        GROUP   BY "transaction_hash","value"
        HAVING  COUNT(*) >= 2
    )
),
/* ---------------- CoinJoin transaction hashes (2021 only) ---------------- */
coinjoin_hashes AS (
    SELECT DISTINCT t."hash"
    FROM   tx_2021 t
    JOIN   equal_val_tx ev  ON ev."transaction_hash" = t."hash"
    WHERE  t."output_count" > 2
      AND  t."output_value" <= t."input_value"
),
/* ---------------- base table: every 2021 tx mapped to calendar month ---------------- */
base AS (
    SELECT  DATE_TRUNC('month', TO_TIMESTAMP_NTZ(t."block_timestamp"/1e6))   AS "month",
            t."hash",
            CASE WHEN cj."hash" IS NOT NULL THEN 1 ELSE 0 END               AS "is_cj"
    FROM    tx_2021 t
    LEFT JOIN coinjoin_hashes cj  ON cj."hash" = t."hash"
),
/* ---------------- input‑UTXO counts per month ---------------- */
inputs AS (
    SELECT  DATE_TRUNC('month', TO_TIMESTAMP_NTZ(tx."block_timestamp"/1e6))  AS "month",
            COUNT(*)                                                         AS "inputs",
            SUM(CASE WHEN cj."hash" IS NOT NULL THEN 1 END)                  AS "cj_inputs"
    FROM    CRYPTO.CRYPTO_BITCOIN.INPUTS i
    JOIN    tx_2021                     tx  ON tx."hash" = i."transaction_hash"
    LEFT JOIN coinjoin_hashes           cj  ON cj."hash" = tx."hash"
    GROUP  BY 1
),
/* ---------------- output‑UTXO counts + BTC value per month ---------------- */
outputs AS (
    SELECT  DATE_TRUNC('month', TO_TIMESTAMP_NTZ(tx."block_timestamp"/1e6))  AS "month",
            COUNT(*)                                                         AS "outputs",
            SUM(CASE WHEN cj."hash" IS NOT NULL THEN 1 END)                  AS "cj_outputs",
            SUM(o."value")                                                   AS "total_value",
            SUM(CASE WHEN cj."hash" IS NOT NULL THEN o."value" END)          AS "cj_value"
    FROM    CRYPTO.CRYPTO_BITCOIN.OUTPUTS o
    JOIN    tx_2021                     tx  ON tx."hash" = o."transaction_hash"
    LEFT JOIN coinjoin_hashes           cj  ON cj."hash" = tx."hash"
    GROUP  BY 1
),
/* ---------------- transaction counts per month ---------------- */
tx_counts AS (
    SELECT  "month",
            COUNT(*)                        AS "total_tx",
            SUM("is_cj")                    AS "cj_tx"
    FROM    base
    GROUP  BY 1
),
/* ---------------- assemble CoinJoin statistics per month ---------------- */
stats AS (
    SELECT  t."month",
            ROUND(100.0 * t."cj_tx" / NULLIF(t."total_tx", 0), 1)                                    AS pct_tx_coinjoin,
            ROUND(
                   100.0 * (
                            COALESCE(i."cj_inputs"  / NULLIF(i."inputs",  0), 0) +
                            COALESCE(o."cj_outputs" / NULLIF(o."outputs", 0), 0)
                          ) / 2
                 , 1)                                                                               AS pct_utxo_coinjoin,
            ROUND(100.0 * COALESCE(o."cj_value", 0) / NULLIF(o."total_value", 0), 1)                AS pct_volume_coinjoin
    FROM    tx_counts t
    JOIN    inputs    i ON i."month" = t."month"
    JOIN    outputs   o ON o."month" = t."month"
)
/* ---------------- month with the highest CoinJoin volume share ---------------- */
SELECT
    EXTRACT(month FROM "month")                AS month,
    pct_tx_coinjoin                            AS percent_tx_coinjoin,
    pct_utxo_coinjoin                          AS percent_utxo_coinjoin,
    pct_volume_coinjoin                        AS percent_volume_coinjoin
FROM   stats
ORDER  BY pct_volume_coinjoin DESC NULLS LAST, month
LIMIT  1;