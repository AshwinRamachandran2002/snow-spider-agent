SELECT
  YEAR(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "Year",
  MONTH(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "Month_num",
  TO_CHAR(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6), 'Mon') AS "Month",
  COUNT(*) AS "Monthly_Transaction_Count",
  ROUND(COUNT(*) / MAX(DATEDIFF(
    'second',
    DATE_TRUNC('month', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)),
    DATEADD('month', 1, DATE_TRUNC('month', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)))
  )), 4) AS "Computed_Transactions_Per_Second"
FROM
  GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS
WHERE
  "block_timestamp" IS NOT NULL
    AND "block_timestamp" > 0
    AND YEAR(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) = 2023
GROUP BY
  "Year",
  "Month_num",
  "Month"
ORDER BY
  "Monthly_Transaction_Count" DESC NULLS LAST;