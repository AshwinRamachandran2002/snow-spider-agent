WITH tx AS (   -- Bitcoin transactions since 1‑Jul‑2023
    SELECT
        "hash",
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000))  AS "month",
        "input_count",
        "output_count",
        "input_value",
        "output_value"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" >= 1688169600000000                                   -- 2023‑07‑01 00:00:00 UTC
),

-- Transactions that have >2 outputs **and** at least one duplicated output value
outputs_agg AS (
    SELECT
        "transaction_hash",
        COUNT(*)                AS "tot_out",
        COUNT(DISTINCT "value") AS "distinct_out"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    WHERE "block_timestamp" >= 1688169600000000
    GROUP BY "transaction_hash"
    HAVING COUNT(*) > 2                     -- more than two outputs
       AND COUNT(DISTINCT "value") < COUNT(*)   -- at least one repeated value
),

-- Flag CoinJoin transactions
classified AS (
    SELECT
        t.*,
        CASE
            WHEN oa."transaction_hash" IS NOT NULL       -- duplicated outputs present
             AND t."output_count" > 2                    -- >2 outputs (safety check)
             AND t."output_value" <= t."input_value"     -- value‑preserving
            THEN 1
            ELSE 0
        END AS "is_coinjoin"
    FROM tx AS t
    LEFT JOIN outputs_agg AS oa
           ON t."hash" = oa."transaction_hash"
),

-- Aggregate monthly totals & CoinJoin subtotals
monthly AS (
    SELECT
        "month",
        COUNT(*)                                           AS "tot_tx",
        SUM("input_count" + "output_count")                AS "tot_utxos",
        SUM("input_value")                                 AS "tot_volume",
        SUM(CASE WHEN "is_coinjoin" = 1 THEN 1 ELSE 0 END) AS "cj_tx",
        SUM(CASE WHEN "is_coinjoin" = 1
                 THEN "input_count" + "output_count" ELSE 0 END) AS "cj_utxos",
        SUM(CASE WHEN "is_coinjoin" = 1 THEN "input_value" ELSE 0 END) AS "cj_volume"
    FROM classified
    GROUP BY "month"
)

-- Final percentages
SELECT
    TO_CHAR("month", 'YYYY-MM')                                              AS "month",
    ROUND(100.0 * "cj_tx"     / NULLIF("tot_tx"    ,0), 4)  AS "pct_coinjoin_transactions",
    ROUND(100.0 * "cj_utxos"  / NULLIF("tot_utxos" ,0), 4)  AS "pct_coinjoin_utxos",
    ROUND(100.0 * "cj_volume" / NULLIF("tot_volume",0), 4)  AS "pct_coinjoin_volume"
FROM monthly
ORDER BY "month" NULLS LAST;