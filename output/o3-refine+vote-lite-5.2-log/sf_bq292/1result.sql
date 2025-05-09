WITH txs AS (   -- Bitcoin transactions from July‑2023 onward
    SELECT
        "hash",
        "block_timestamp",
        "input_count",
        "output_count",
        "input_value" :: NUMBER        AS "input_value",
        "output_value":: NUMBER        AS "output_value",
        "outputs"                      -- needed later to detect duplicate amounts
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" >= 1688169600000000      -- 2023‑07‑01 in µs
),   

-- transactions whose outputs contain at least one duplicated value
dup_value_txs AS (
    SELECT DISTINCT t."hash"
    FROM txs t,
         LATERAL FLATTEN(input => t."outputs") f
    GROUP BY t."hash"
    HAVING COUNT(DISTINCT (f.value:"value")::NUMBER) < COUNT(*)   -- duplicate detected
),

-- CoinJoin transactions (definition in task)
coinjoin AS (
    SELECT
        t."hash",
        t."block_timestamp",
        t."input_count",
        t."output_count",
        t."input_value",
        t."output_value",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(t."block_timestamp" / 1e6)) AS "month"
    FROM   txs t
    JOIN   dup_value_txs d ON t."hash" = d."hash"
    WHERE  t."output_count" > 2
      AND  t."output_value" <= t."input_value"
),

-- monthly totals for the whole Bitcoin network
all_month AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "month",
        COUNT(*)                                   AS "tot_tx",
        SUM("input_count" + "output_count")        AS "tot_utxos",
        SUM("input_value")                         AS "tot_volume"
    FROM   txs
    GROUP  BY 1
),

-- monthly totals for CoinJoin activity
cj_month AS (
    SELECT
        "month",
        COUNT(*)                                   AS "cj_tx",
        SUM("input_count" + "output_count")        AS "cj_utxos",
        SUM("input_value")                         AS "cj_volume"
    FROM   coinjoin
    GROUP  BY 1
)

SELECT
    a."month",
    ROUND(COALESCE(c."cj_tx",     0) * 100.0 / a."tot_tx",    4) AS "tx_percentage",
    ROUND(COALESCE(c."cj_utxos",  0) * 100.0 / a."tot_utxos", 4) AS "utxo_percentage",
    ROUND(COALESCE(c."cj_volume", 0) * 100.0 / a."tot_volume",4) AS "volume_percentage"
FROM   all_month a
LEFT   JOIN cj_month c  ON a."month" = c."month"
ORDER  BY a."month";