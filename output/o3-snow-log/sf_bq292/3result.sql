WITH btc_tx AS (   -- Bitcoin txs since 1 July 2023
    SELECT
        "hash"                                   AS tx_hash,
        "block_number"                           AS block_height,
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP("block_timestamp" / 1000000)
        )                                        AS month,
        "input_count"                            AS input_count,
        "output_count"                           AS output_count,
        "input_value"                            AS input_value,
        "output_value"                           AS output_value
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" >= 1688169600000000      -- 2023-07-01 00:00:00 UTC in µs
),

/* transactions that have ≥2 identical-value outputs */
dup_value_tx AS (
    SELECT DISTINCT "transaction_hash" AS tx_hash
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    GROUP BY "transaction_hash", "value"
    HAVING COUNT(*) > 1
),

/* CoinJoin classification */
coinjoin_tx AS (
    SELECT t.tx_hash
    FROM btc_tx t
    JOIN dup_value_tx d   ON t.tx_hash = d.tx_hash
    WHERE t.output_count > 2
      AND t.output_value <= t.input_value
),

/* monthly aggregates */
monthly AS (
    SELECT
        month,

        /* transactions */
        COUNT(*)                                                   AS total_tx,
        COUNT(CASE WHEN tx_hash IN (SELECT tx_hash FROM coinjoin_tx) THEN 1 END)
                                                                  AS coinjoin_tx,

        /* UTXOs touched (inputs + outputs) */
        SUM(input_count + output_count)                            AS total_utxos,
        SUM(CASE WHEN tx_hash IN (SELECT tx_hash FROM coinjoin_tx)
                 THEN input_count + output_count END)              AS coinjoin_utxos,

        /* volume (input value) */
        SUM(input_value)                                           AS total_volume,
        SUM(CASE WHEN tx_hash IN (SELECT tx_hash FROM coinjoin_tx)
                 THEN input_value END)                             AS coinjoin_volume
    FROM btc_tx
    GROUP BY month
)

SELECT
    month                                                    AS "MONTH",
    ROUND(coinjoin_tx      * 100.0 / NULLIF(total_tx     ,0), 4) AS "TX_%_COINJOIN",
    ROUND(coinjoin_utxos   * 100.0 / NULLIF(total_utxos  ,0), 4) AS "UTXO_%_COINJOIN",
    ROUND(coinjoin_volume  * 100.0 / NULLIF(total_volume ,0), 4) AS "VOLUME_%_COINJOIN"
FROM monthly
ORDER BY month;