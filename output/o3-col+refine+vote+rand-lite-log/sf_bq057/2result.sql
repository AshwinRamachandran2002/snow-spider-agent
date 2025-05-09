WITH dup_value_tx AS (   -- txids that have at least two equal-valued outputs
    SELECT "transaction_hash"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    GROUP BY "transaction_hash"
    HAVING COUNT(*) > COUNT(DISTINCT "value")
),
tx_2021 AS (             -- 2021 bitcoin transactions, flagging CoinJoin ones
    SELECT
        t.*,
        CASE
            WHEN t."output_count" > 2                       -- fan-out
             AND t."output_value" <= t."input_value"        -- value-conserving
             AND t."hash" IN (SELECT "transaction_hash" FROM dup_value_tx)
            THEN 1 ELSE 0
        END AS "is_cj"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS t
    WHERE t."block_timestamp" BETWEEN 1609459200000000        -- 2021-01-01
                                  AND 1640995199000000        -- 2021-12-31
),
month_stats AS (         -- aggregate totals & CoinJoin subtotals per month
    SELECT
        TO_CHAR(TO_TIMESTAMP("block_timestamp"/1e6),'MM') AS "month_str",
        COUNT(*)                              AS total_tx,
        SUM("is_cj")                          AS cj_tx,
        SUM("input_count")                    AS total_inputs,
        SUM("output_count")                   AS total_outputs,
        SUM(CASE WHEN "is_cj"=1 THEN "input_count"  END) AS cj_inputs,
        SUM(CASE WHEN "is_cj"=1 THEN "output_count" END) AS cj_outputs,
        SUM("output_value")                   AS total_volume,
        SUM(CASE WHEN "is_cj"=1 THEN "output_value" END) AS cj_volume
    FROM tx_2021
    GROUP BY "month_str"
),
metrics AS (             -- convert to percentages (rounded to 1 decimal place)
    SELECT
        CAST("month_str" AS INT)                                            AS "month",
        ROUND(cj_tx       * 100.0 / NULLIF(total_tx     ,0),1)              AS pct_tx,
        ROUND(((cj_inputs * 100.0 / NULLIF(total_inputs,0)) +
               (cj_outputs* 100.0 / NULLIF(total_outputs,0)))/2 ,1)        AS pct_utxos,
        ROUND(cj_volume   * 100.0 / NULLIF(total_volume ,0),1)              AS pct_volume
    FROM month_stats
)
SELECT *
FROM metrics
ORDER BY pct_volume DESC NULLS LAST     -- month with highest CoinJoin-volume share
LIMIT 1;