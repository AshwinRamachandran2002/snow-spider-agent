WITH dup_value_tx AS (   --  txs that have ≥1 duplicated output amount
    SELECT "transaction_hash"
    FROM   CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    GROUP  BY "transaction_hash"
    HAVING COUNT(*) > COUNT(DISTINCT "value")
),

coinjoin_base AS (       --  CoinJoin‑like txs (rule set in task)
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(t."block_timestamp"/1000000)) AS "month",
        t."input_count",
        t."output_count",
        t."input_value"
    FROM   CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS t
    JOIN   dup_value_tx d
          ON d."transaction_hash" = t."hash"
    WHERE  t."output_count"  > 2
      AND  t."output_value" <= t."input_value"
      AND  t."is_coinbase"  = FALSE
      AND  TO_TIMESTAMP_NTZ(t."block_timestamp"/1000000) >= '2023-07-01'
),

coinjoin_month AS (      --  monthly CoinJoin aggregates
    SELECT
        "month",
        COUNT(*)                                           AS "cj_tx",
        SUM("input_count" + "output_count")                AS "cj_utxos",
        SUM("input_value")                                 AS "cj_volume"
    FROM   coinjoin_base
    GROUP  BY "month"
),

all_tx_month AS (        --  monthly network totals
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("block_timestamp"/1000000)) AS "month",
        COUNT(*)                                           AS "total_tx",
        SUM("input_count" + "output_count")                AS "total_utxos",
        SUM("input_value")                                 AS "total_volume"
    FROM   CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE  TO_TIMESTAMP_NTZ("block_timestamp"/1000000) >= '2023-07-01'
    GROUP  BY "month"
)

SELECT
    TO_CHAR(a."month", 'YYYY-MM')                                 AS "month",
    ROUND(100 * c."cj_tx"     / NULLIF(a."total_tx",    0), 4)    AS "coinjoin_tx_pct",
    ROUND(100 * c."cj_utxos"  / NULLIF(a."total_utxos", 0), 4)    AS "coinjoin_utxo_pct",
    ROUND(100 * c."cj_volume" / NULLIF(a."total_volume",0), 4)    AS "coinjoin_volume_pct"
FROM   all_tx_month a
LEFT   JOIN coinjoin_month c USING ("month")
ORDER  BY a."month";