WITH monthly_stats AS (
  SELECT
    EXTRACT(MONTH FROM "block_timestamp_month") AS "Month",
    COUNT(CASE WHEN "is_coinbase" = false THEN 1 END) AS "Total_Transactions",
    COUNT(CASE WHEN "is_coinbase" = false AND "input_count" >= 5 AND "output_count" >= 5 THEN 1 END) AS "CoinJoin_Transactions",
    SUM(CASE WHEN "is_coinbase" = false THEN "output_value" END) AS "Total_Volume",
    SUM(CASE WHEN "is_coinbase" = false AND "input_count" >= 5 AND "output_count" >=5 THEN "output_value" END) AS "CoinJoin_Volume",
    AVG(CASE WHEN "is_coinbase" = false AND "input_count" >= 5 AND "output_count" >=5 THEN "input_count"::FLOAT / NULLIF("output_count", 0) END) AS "Avg_Input_Output_Ratio"
  FROM "CRYPTO"."CRYPTO_BITCOIN"."TRANSACTIONS"
  WHERE "block_timestamp_month" >= '2021-01-01' AND "block_timestamp_month" < '2022-01-01'
  GROUP BY "Month"
), final_stats AS (
  SELECT
    "Month",
    ("CoinJoin_Transactions"::FLOAT / NULLIF("Total_Transactions", 0)) * 100 AS "Percentage_of_CoinJoin_Transactions",
    "Avg_Input_Output_Ratio",
    ("CoinJoin_Volume" / NULLIF("Total_Volume", 0)) * 100 AS "CoinJoin_Transaction_Volume_Proportion"
  FROM monthly_stats
)
SELECT
  "Month",
  ROUND("Percentage_of_CoinJoin_Transactions",4) AS "Percentage_of_CoinJoin_Transactions",
  ROUND("Avg_Input_Output_Ratio",4) AS "Average_Input_Output_UTXOs_Ratio",
  ROUND("CoinJoin_Transaction_Volume_Proportion",4) AS "CoinJoin_Transaction_Volume_Proportion"
FROM final_stats
ORDER BY "CoinJoin_Transaction_Volume_Proportion" DESC NULLS LAST
LIMIT 1;