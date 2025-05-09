WITH total_transactions AS (
  SELECT
    TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP_LTZ("block_timestamp" / 1000000)), 'Mon-YYYY') AS "Month",
    COUNT(*) AS total_transactions,
    SUM("output_count") AS total_outputs,
    SUM("output_value") AS total_volume
  FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
  WHERE "block_timestamp" >= 1688169600000000
  GROUP BY "Month"
),
coinjoin_transactions AS (
  SELECT
    TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP_LTZ("block_timestamp" / 1000000)), 'Mon-YYYY') AS "Month",
    COUNT(*) AS coinjoin_transactions,
    SUM("output_count") AS coinjoin_outputs,
    SUM("output_value") AS coinjoin_volume
  FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
  WHERE "block_timestamp" >= 1688169600000000
    AND "input_count" > 10 AND "output_count" > 10
  GROUP BY "Month"
),
merged_data AS (
  SELECT
    t."Month",
    t.total_transactions,
    NVL(c.coinjoin_transactions, 0) AS coinjoin_transactions,
    t.total_outputs,
    NVL(c.coinjoin_outputs, 0) AS coinjoin_outputs,
    t.total_volume,
    NVL(c.coinjoin_volume, 0) AS coinjoin_volume
  FROM total_transactions t
  LEFT JOIN coinjoin_transactions c ON t."Month" = c."Month"
)
SELECT
  m."Month",
  ROUND((m.coinjoin_transactions * 100.0) / m.total_transactions, 4) AS "Percentage_of_CoinJoin_Transactions",
  ROUND((m.coinjoin_outputs * 100.0) / m.total_outputs, 4) AS "Percentage_of_CoinJoin_UTXOs",
  ROUND((m.coinjoin_volume * 100.0) / m.total_volume, 4) AS "Percentage_of_CoinJoin_Volume"
FROM merged_data m
ORDER BY m."Month";