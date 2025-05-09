WITH base_tx AS (                                                              -- Bitcoin TXs since 1‑Jul‑2023
    SELECT
        "hash",
        "block_timestamp",
        "input_value",
        "output_value",
        "output_count"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" >= 1688169600000000       -- 2023‑07‑01 00:00:00 UTC
),

flagged_tx AS (                                                               -- mark CoinJoin transactions
    SELECT
        bt.*,
        CASE
            WHEN bt."output_count" > 2                                   -- rule 1
             AND bt."output_value" <= bt."input_value"                   -- rule 2
             AND EXISTS (                                                -- rule 3: ≥ 1 duplicated output value
                    SELECT 1
                    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS o
                    WHERE o."transaction_hash" = bt."hash"
                    GROUP BY o."value"
                    HAVING COUNT(*) > 1
                 )
            THEN 1 ELSE 0
        END AS "is_coinjoin"
    FROM base_tx bt
),

monthly AS (                                                                 -- aggregate per month
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000))                     AS "month",
        COUNT(*)                                                                           AS "tx_total",
        COUNT_IF("is_coinjoin" = 1)                                                        AS "tx_coinjoin",
        SUM("output_count")                                                                AS "utxo_total",
        SUM(CASE WHEN "is_coinjoin" = 1 THEN "output_count" END)                           AS "utxo_coinjoin",
        SUM("input_value")                                                                 AS "vol_total",
        SUM(CASE WHEN "is_coinjoin" = 1 THEN "input_value" END)                            AS "vol_coinjoin"
    FROM flagged_tx
    GROUP BY 1
)

SELECT
    "month",
    ROUND(COALESCE("tx_coinjoin",0)::FLOAT   / NULLIF("tx_total",0),   4) AS "coinjoin_tx_pct",
    ROUND(COALESCE("utxo_coinjoin",0)::FLOAT / NULLIF("utxo_total",0), 4) AS "coinjoin_utxo_pct",
    ROUND(COALESCE("vol_coinjoin",0)::FLOAT  / NULLIF("vol_total",0), 4)  AS "coinjoin_volume_pct"
FROM monthly
ORDER BY "month";