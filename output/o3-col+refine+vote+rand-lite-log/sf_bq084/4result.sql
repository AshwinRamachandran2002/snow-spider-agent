WITH monthly AS (
  SELECT
    DATE_TRUNC('MONTH', TO_TIMESTAMP_LTZ("block_timestamp" / 1e6)) AS "month_start",
    COUNT(*)                                                       AS "monthly_transaction_count",
    DATEDIFF(
      'SECOND',
      DATE_TRUNC('MONTH', TO_TIMESTAMP_LTZ("block_timestamp" / 1e6)),
      DATEADD('MONTH', 1, DATE_TRUNC('MONTH', TO_TIMESTAMP_LTZ("block_timestamp" / 1e6)))
    )                                                             AS "seconds_in_month"
  FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."LOGS"
  WHERE YEAR(TO_TIMESTAMP_LTZ("block_timestamp" / 1e6)) = 2023
  GROUP BY 1
)
SELECT
  YEAR("month_start")                           AS "year",
  MONTH("month_start")                          AS "month",
  "monthly_transaction_count",
  ROUND("monthly_transaction_count" / "seconds_in_month", 4) AS "transactions_per_second"
FROM monthly
ORDER BY "monthly_transaction_count" DESC NULLS LAST;