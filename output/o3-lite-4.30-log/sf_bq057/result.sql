WITH tx AS (         -- explode outputs to count identical values per transaction
    SELECT
        t."hash",
        t."block_timestamp_month"                                      AS "month",
        t."input_value"::FLOAT                                         AS "input_value",
        t."output_value"::FLOAT                                        AS "output_value",
        t."input_count"::INT                                           AS "input_count",
        t."output_count"::INT                                          AS "output_count",
        COUNT(DISTINCT fo.value:"value"::FLOAT)                        AS "distinct_vals"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS t,
         LATERAL FLATTEN(input => t."outputs") fo
    WHERE t."block_timestamp_month" BETWEEN '2021-01-01' AND '2021-12-01'
    GROUP BY t."hash", t."block_timestamp_month",
             t."input_value", t."output_value",
             t."input_count", t."output_count"
),
flagged AS (          -- tag CoinJoin transactions
    SELECT *,
           CASE
                WHEN "output_count" > 2
                 AND "output_value" <= "input_value"
                 AND "output_count" > "distinct_vals"
                THEN 1 ELSE 0
           END                                                       AS "is_cj"
    FROM tx
),
month_stats AS (      -- aggregate monthly numbers
    SELECT
        "month",
        COUNT(*)                                                     AS all_tx,
        SUM("is_cj")                                                 AS cj_tx,
        SUM("input_count")                                           AS all_inputs,
        SUM("output_count")                                          AS all_outputs,
        SUM(CASE WHEN "is_cj" = 1 THEN "input_count"  END)           AS cj_inputs,
        SUM(CASE WHEN "is_cj" = 1 THEN "output_count" END)           AS cj_outputs,
        SUM("input_value")                                           AS all_vol,
        SUM(CASE WHEN "is_cj" = 1 THEN "input_value" END)            AS cj_vol
    FROM flagged
    GROUP BY "month"
),
ranked AS (           -- compute percentages & rank by CoinJoin volume share
    SELECT
        "month",
        ROUND(100.0 * cj_tx / NULLIF(all_tx, 0), 1)                                            AS percent_tx_coinjoin,
        ROUND(100.0 * ( (cj_inputs / NULLIF(all_inputs ,0)::FLOAT) +
                        (cj_outputs/ NULLIF(all_outputs,0)::FLOAT) ) / 2 , 1)                  AS percent_utxo_coinjoin,
        ROUND(100.0 * cj_vol / NULLIF(all_vol, 0), 1)                                          AS percent_volume_coinjoin,
        RANK() OVER (ORDER BY cj_vol / NULLIF(all_vol,0) DESC)                                 AS rnk
    FROM month_stats
)
SELECT
    EXTRACT(month FROM "month")                                       AS month,
    percent_tx_coinjoin,
    percent_utxo_coinjoin,
    percent_volume_coinjoin
FROM ranked
WHERE rnk = 1
ORDER BY month;