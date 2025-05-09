/*  Monthly CoinJoin penetration in Bitcoin since 1-Jul-2023
    – percentage of transactions, UTXOs (inputs) and transferred volume      */

WITH /* --------------------------------------------------------------- *
     * 1) Identify CoinJoin transactions ( >2 outputs, value dupes etc.) *
     * ----------------------------------------------------------------- */
coinjoin_tx AS (
    SELECT DISTINCT
           t."hash",
           TO_CHAR(
               TO_TIMESTAMP_NTZ(t."block_timestamp" / 1e6),
               'YYYY-MM'
           ) AS "month"
    FROM   CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS  t,
           LATERAL FLATTEN (INPUT => t."outputs") f
    WHERE  t."block_timestamp" >= 1688169600000000      -- 01-Jul-2023
      AND  t."output_count"  > 2                       -- > 2 outputs
      AND  t."output_value" <= t."input_value"         -- sane value
    QUALIFY                                             -- ▸ at least one duplicate output value
           COUNT(*)                         OVER (PARTITION BY t."hash") >
           COUNT(DISTINCT f.value:"value"::NUMBER)
                                            OVER (PARTITION BY t."hash")
),

/* --------------------------------------------------------------- *
 * 2) Monthly totals & CoinJoin counts (transactions)              *
 * --------------------------------------------------------------- */
tx_monthly AS (
    SELECT
        TO_CHAR(
            TO_TIMESTAMP_NTZ("block_timestamp" / 1e6),
            'YYYY-MM'
        )                           AS "month",
        COUNT(*)                    AS "tx_total",
        SUM(CASE WHEN "hash" IN (SELECT "hash" FROM coinjoin_tx)
                 THEN 1 ELSE 0 END) AS "tx_coinjoin"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" >= 1688169600000000
    GROUP BY 1
),

/* --------------------------------------------------------------- *
 * 3) Monthly UTXO (input) counts, tagging CoinJoin inputs         *
 * --------------------------------------------------------------- */
utxo_monthly AS (
    SELECT
        TO_CHAR(
            TO_TIMESTAMP_NTZ(t."block_timestamp" / 1e6),
            'YYYY-MM'
        )                           AS "month",
        COUNT(*)                    AS "utxo_total",
        COUNT(CASE WHEN c."hash" IS NOT NULL THEN 1 END) AS "utxo_coinjoin"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS        i
    JOIN CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS  t
             ON t."hash" = i."transaction_hash"
    LEFT JOIN coinjoin_tx                    c
             ON c."hash" = t."hash"
    WHERE t."block_timestamp" >= 1688169600000000
    GROUP BY 1
),

/* --------------------------------------------------------------- *
 * 4) Monthly volume (input value) totals & CoinJoin share         *
 * --------------------------------------------------------------- */
vol_monthly AS (
    SELECT
        TO_CHAR(
            TO_TIMESTAMP_NTZ("block_timestamp" / 1e6),
            'YYYY-MM'
        )                                            AS "month",
        SUM("input_value")                           AS "vol_total",
        SUM(CASE WHEN "hash" IN (SELECT "hash" FROM coinjoin_tx)
                 THEN "input_value" ELSE 0 END)      AS "vol_coinjoin"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" >= 1688169600000000
    GROUP BY 1
)

/* --------------------------------------------------------------- *
 * 5) Assemble percentages                                         *
 * --------------------------------------------------------------- */
SELECT
    t."month",
    ROUND(100.0 * t."tx_coinjoin"  / t."tx_total",   4) AS "pct_tx_coinjoin",
    ROUND(100.0 * u."utxo_coinjoin"/ u."utxo_total", 4) AS "pct_utxo_coinjoin",
    ROUND(100.0 * v."vol_coinjoin" / NULLIF(v."vol_total",0), 6)
                                                   AS "pct_volume_coinjoin"
FROM tx_monthly t
JOIN utxo_monthly u USING ("month")
JOIN vol_monthly  v USING ("month")
ORDER BY t."month";