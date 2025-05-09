WITH MonthStats AS (
  SELECT
    EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "Month",
    COUNT(DISTINCT "transaction_hash") AS "Transaction_Count",
    (MAX("block_timestamp") - MIN("block_timestamp")) / 1e6 AS "Duration_Seconds"
  FROM
    "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS"
  WHERE
    EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) = 2023
  GROUP BY
    EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))
)
SELECT
  TO_CHAR("Month") AS "Month",
  "Transaction_Count",
  ROUND("Transaction_Count" / "Duration_Seconds", 4) AS "Transactions_Per_Second"
FROM
  MonthStats
ORDER BY
  "Transaction_Count" DESC NULLS LAST;