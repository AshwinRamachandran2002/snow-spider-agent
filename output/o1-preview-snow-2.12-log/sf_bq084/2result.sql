SELECT
  "Year",
  "Month_num",
  "Month",
  "Monthly_Transaction_Count",
  ROUND(("Monthly_Transaction_Count" / "Seconds_In_Month"), 4) AS "Computed_Transactions_Per_Second"
FROM
(
  SELECT
    YEAR(TO_TIMESTAMP_NTZ("block_timestamp", 6)) AS "Year",
    MONTH(TO_TIMESTAMP_NTZ("block_timestamp", 6)) AS "Month_num",
    TO_CHAR(TO_TIMESTAMP_NTZ("block_timestamp", 6), 'Mon') AS "Month",
    COUNT(*) AS "Monthly_Transaction_Count",
    DATEDIFF(
      'second',
      DATE_FROM_PARTS(YEAR(TO_TIMESTAMP_NTZ("block_timestamp", 6)), MONTH(TO_TIMESTAMP_NTZ("block_timestamp", 6)), 1),
      DATEADD(
        'month',
        1,
        DATE_FROM_PARTS(YEAR(TO_TIMESTAMP_NTZ("block_timestamp", 6)), MONTH(TO_TIMESTAMP_NTZ("block_timestamp", 6)), 1)
      )
    ) AS "Seconds_In_Month"
  FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS"
  WHERE YEAR(TO_TIMESTAMP_NTZ("block_timestamp", 6)) = 2023
  GROUP BY
    YEAR(TO_TIMESTAMP_NTZ("block_timestamp", 6)),
    MONTH(TO_TIMESTAMP_NTZ("block_timestamp", 6)),
    TO_CHAR(TO_TIMESTAMP_NTZ("block_timestamp", 6), 'Mon')
)
ORDER BY "Monthly_Transaction_Count" DESC NULLS LAST;