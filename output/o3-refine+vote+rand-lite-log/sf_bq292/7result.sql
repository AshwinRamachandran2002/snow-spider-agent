/* -----------------------------------------------------------
   CoinJoin activity in Bitcoin since 1‑Jul‑2023
   -----------------------------------------------------------
   Criteria for a CoinJoin transaction
     • more than two outputs
     • total output value ≤ total input value
     • ≥ 1 duplicated‑value output
----------------------------------------------------------------*/
WITH
/* 1. Detect txs that have at least one duplicated output value */
outputs_dup AS (
    SELECT
        "transaction_hash",
        MAX(CASE WHEN value_cnt > 1 THEN 1 ELSE 0 END) AS has_dup
    FROM (
        SELECT
            "transaction_hash",
            "value",
            COUNT(*) AS value_cnt
        FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
        GROUP BY "transaction_hash", "value"
    )
    GROUP BY "transaction_hash"
),

/* 2. Transaction‑level facts plus CoinJoin flag */
tx AS (
    SELECT
        t."hash"                                                                AS "TX_HASH",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(t."block_timestamp" / 1e6))        AS "MONTH",
        t."input_count"                                                         AS "INPUT_COUNT",
        t."output_count"                                                        AS "OUTPUT_COUNT",
        t."input_value"                                                         AS "INPUT_VALUE",
        t."output_value"                                                        AS "OUTPUT_VALUE",
        COALESCE(d.has_dup, 0)                                                  AS "HAS_DUP",
        /* CoinJoin classification */
        CASE
            WHEN t."output_count" > 2
             AND t."output_value" <= t."input_value"
             AND COALESCE(d.has_dup, 0) = 1
            THEN 1 ELSE 0
        END                                                                     AS "IS_COINJOIN"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS t
    LEFT JOIN outputs_dup d
           ON d."transaction_hash" = t."hash"
    WHERE TO_TIMESTAMP_NTZ(t."block_timestamp" / 1e6) >= '2023-07-01'
)

/* 3. Monthly CoinJoin percentages */
SELECT
    "MONTH",
    /* 1. % of transactions */
    ROUND(
        SUM("IS_COINJOIN")::FLOAT
        / NULLIF(COUNT(*), 0) * 100, 4
    ) AS "TX_%_COINJOIN",

    /* 2. % of UTXOs (inputs + outputs) */
    ROUND(
        SUM(CASE WHEN "IS_COINJOIN" = 1
                 THEN ("INPUT_COUNT" + "OUTPUT_COUNT")
                 ELSE 0 END)::FLOAT
        / NULLIF(SUM("INPUT_COUNT" + "OUTPUT_COUNT"), 0) * 100, 4
    ) AS "UTXO_%_COINJOIN",

    /* 3. % of volume (by input value) */
    ROUND(
        SUM(CASE WHEN "IS_COINJOIN" = 1
                 THEN "INPUT_VALUE"
                 ELSE 0 END)::FLOAT
        / NULLIF(SUM("INPUT_VALUE"), 0) * 100, 4
    ) AS "VOLUME_%_COINJOIN"
FROM tx
GROUP BY "MONTH"
ORDER BY "MONTH";