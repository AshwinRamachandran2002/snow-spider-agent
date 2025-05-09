WITH total_volume AS (
  SELECT
    EXTRACT(MONTH FROM "block_timestamp_month") AS "Month",
    SUM("input_value") AS "Total_Volume"
  FROM
    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
  WHERE
    "block_timestamp_month" >= '2021-01-01'
    AND "block_timestamp_month" < '2022-01-01'
  GROUP BY
    "Month"
),
coinjoin_volume AS (
  SELECT
    EXTRACT(MONTH FROM "block_timestamp_month") AS "Month",
    SUM("input_value") AS "CoinJoin_Volume"
  FROM
    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
  WHERE
    "block_timestamp_month" >= '2021-01-01'
    AND "block_timestamp_month" < '2022-01-01'
    AND "is_coinbase" = FALSE
    AND "input_count" >= 5
    AND "output_count" >= 5
  GROUP BY
    "Month"
),
transaction_counts AS (
  SELECT
    EXTRACT(MONTH FROM "block_timestamp_month") AS "Month",
    COUNT(*) AS "Total_Transactions"
  FROM
    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
  WHERE
    "block_timestamp_month" >= '2021-01-01'
    AND "block_timestamp_month" < '2022-01-01'
    AND "is_coinbase" = FALSE
  GROUP BY
    "Month"
),
coinjoin_transaction_counts AS (
  SELECT
    EXTRACT(MONTH FROM "block_timestamp_month") AS "Month",
    COUNT(*) AS "CoinJoin_Transactions"
  FROM
    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
  WHERE
    "block_timestamp_month" >= '2021-01-01'
    AND "block_timestamp_month" < '2022-01-01'
    AND "is_coinbase" = FALSE
    AND "input_count" >= 5
    AND "output_count" >= 5
  GROUP BY
    "Month"
),
average_ratio AS (
  SELECT
    EXTRACT(MONTH FROM "block_timestamp_month") AS "Month",
    AVG("input_count"::FLOAT / NULLIF("output_count", 0)) AS "Average_Input_Output_UTXOs_Ratio"
  FROM
    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
  WHERE
    "block_timestamp_month" >= '2021-01-01'
    AND "block_timestamp_month" < '2022-01-01'
    AND "is_coinbase" = FALSE
    AND "input_count" >= 5
    AND "output_count" >= 5
  GROUP BY
    "Month"
)
SELECT
  total_volume."Month",
  ROUND((coinjoin_transaction_counts."CoinJoin_Transactions"::FLOAT / transaction_counts."Total_Transactions") * 100, 1) AS "Percentage_of_CoinJoin_Transactions",
  ROUND(average_ratio."Average_Input_Output_UTXOs_Ratio", 1) AS "Average_Input_Output_UTXOs_Ratio",
  ROUND((coinjoin_volume."CoinJoin_Volume" / total_volume."Total_Volume") * 100, 1) AS "CoinJoin_Transaction_Volume_Proportion"
FROM
  total_volume
JOIN
  coinjoin_volume ON total_volume."Month" = coinjoin_volume."Month"
JOIN
  transaction_counts ON total_volume."Month" = transaction_counts."Month"
JOIN
  coinjoin_transaction_counts ON total_volume."Month" = coinjoin_transaction_counts."Month"
JOIN
  average_ratio ON total_volume."Month" = average_ratio."Month"
ORDER BY
  "CoinJoin_Transaction_Volume_Proportion" DESC NULLS LAST
LIMIT 1;