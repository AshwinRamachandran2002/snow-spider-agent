WITH tx_2021 AS (
    SELECT
        "hash"                                              AS tx_hash,
        "block_timestamp",
        "output_value",
        "input_value",
        "output_count",
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000)) AS month_start
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" BETWEEN 1609459200000000 /* 2021‑01‑01 */
                               AND     1640995200000000 /* 2022‑01‑01 */
), -------------------------------------------------------------------
equal_value_txs AS (          /* txs that have ≥2 identical‑value outputs */
    SELECT DISTINCT "transaction_hash" AS tx_hash
    FROM (
        SELECT "transaction_hash", "value"
        FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
        WHERE "block_timestamp" BETWEEN 1609459200000000 AND 1640995200000000
    )
    GROUP BY "transaction_hash", "value"
    HAVING COUNT(*) >= 2
), -------------------------------------------------------------------
tx_flag AS (                  /* identify CoinJoin transactions          */
    SELECT
        t.*,
        CASE
            WHEN t."output_count" > 2
             AND t."output_value" <= t."input_value"
             AND ev.tx_hash IS NOT NULL
            THEN 1 ELSE 0
        END AS is_coinjoin
    FROM tx_2021 t
    LEFT JOIN equal_value_txs ev
           ON t.tx_hash = ev.tx_hash
), -------------------------------------------------------------------
monthly_tx AS (
    SELECT
        month_start,
        COUNT(*)                                            AS total_tx,
        SUM(is_coinjoin)                                   AS coinjoin_tx,
        SUM("output_value")                                AS total_vol,
        SUM(CASE WHEN is_coinjoin = 1 THEN "output_value" ELSE 0 END)
                                                          AS coinjoin_vol
    FROM tx_flag
    GROUP BY month_start
), -------------------------------------------------------------------
monthly_inputs AS (
    SELECT
        tx.month_start,
        COUNT(*)                                AS total_inputs,
        SUM(tx.is_coinjoin)                     AS coinjoin_inputs
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS   i
    JOIN tx_flag                        tx ON i."transaction_hash" = tx.tx_hash
    GROUP BY tx.month_start
), -------------------------------------------------------------------
monthly_outputs AS (
    SELECT
        tx.month_start,
        COUNT(*)                                AS total_outputs,
        SUM(tx.is_coinjoin)                     AS coinjoin_outputs
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS  o
    JOIN tx_flag                        tx ON o."transaction_hash" = tx.tx_hash
    GROUP BY tx.month_start
), -------------------------------------------------------------------
monthly_stats AS (
    SELECT
        t.month_start,
        ROUND(coinjoin_tx   * 100.0 / NULLIF(total_tx   ,0), 1) AS pct_tx_coinjoin,
        ROUND( ( coinjoin_inputs  * 100.0 / NULLIF(total_inputs ,0)
               + coinjoin_outputs * 100.0 / NULLIF(total_outputs,0) ) / 2 , 1)
                                                             AS pct_utxo_coinjoin,
        ROUND(coinjoin_vol * 100.0 / NULLIF(total_vol ,0), 1)  AS pct_vol_coinjoin
    FROM monthly_tx      t
    JOIN monthly_inputs  i USING (month_start)
    JOIN monthly_outputs o USING (month_start)
) ---------------------------------------------------------------------
SELECT
    EXTRACT(month FROM month_start)         AS month,
    pct_tx_coinjoin                         AS pct_transactions_coinjoin,
    pct_utxo_coinjoin                       AS pct_utxos_coinjoin,
    pct_vol_coinjoin                        AS pct_volume_coinjoin
FROM monthly_stats
ORDER BY pct_vol_coinjoin DESC NULLS LAST, month
LIMIT 1;