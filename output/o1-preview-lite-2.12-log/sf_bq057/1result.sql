WITH transactions_2021 AS (
  SELECT
    t."hash",
    EXTRACT(MONTH FROM t."block_timestamp_month") AS "Month",
    t."input_count",
    t."output_count",
    t."input_value",
    t."output_value",
    t."is_coinbase"
  FROM "CRYPTO"."CRYPTO_BITCOIN"."TRANSACTIONS" t
  WHERE
    t."block_timestamp_month" >= '2021-01-01' AND t."block_timestamp_month" < '2022-01-01'
    AND t."is_coinbase" = FALSE
    AND t."input_value" IS NOT NULL
    AND t."input_value" > 0
),
outputs_per_transaction AS (
  SELECT
    o."transaction_hash" AS "hash",
    COUNT(*) AS "output_count",
    COUNT(DISTINCT o."value") AS "distinct_output_values_count"
  FROM "CRYPTO"."CRYPTO_BITCOIN"."OUTPUTS" o
  WHERE o."transaction_hash" IN (SELECT "hash" FROM transactions_2021)
  GROUP BY o."transaction_hash"
),
coinjoin_transactions AS (
  SELECT
    t."hash",
    t."Month",
    t."input_count",
    t."output_count",
    t."input_value",
    t."input_count"::FLOAT / NULLIF(t."output_count", 0)::FLOAT AS "input_output_ratio"
  FROM
    transactions_2021 t
    JOIN outputs_per_transaction ovc ON t."hash" = ovc."hash"
  WHERE
    t."input_count" >= 5
    AND t."output_count" >= 5
    AND ovc."distinct_output_values_count" <= 2
),
monthly_totals AS (
  SELECT
    "Month",
    COUNT(*) AS "month_total_transactions",
    SUM("input_value") AS "month_total_volume"
  FROM transactions_2021
  GROUP BY "Month"
  HAVING COUNT(*) > 0 AND SUM("input_value") > 0
)
SELECT
  c."Month",
  ROUND((COUNT(*) * 100.0) / NULLIF(t."month_total_transactions", 0), 4) AS "Percentage_of_CoinJoin_Transactions",
  ROUND(AVG(c."input_output_ratio"), 4) AS "Average_Input_Output_UTXOs_Ratio",
  ROUND((SUM(c."input_value") * 100.0) / NULLIF(t."month_total_volume", 0), 4) AS "CoinJoin_Transaction_Volume_Proportion"
FROM
  coinjoin_transactions c
  JOIN monthly_totals t ON c."Month" = t."Month"
GROUP BY
  c."Month", t."month_total_transactions", t."month_total_volume"
ORDER BY
  "CoinJoin_Transaction_Volume_Proportion" DESC NULLS LAST
LIMIT 1;