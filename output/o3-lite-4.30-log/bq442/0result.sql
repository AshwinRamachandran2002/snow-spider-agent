SELECT
  trade_report_id,
  close_price
FROM (
  SELECT
    `TradeReportID`                                  AS trade_report_id,
    ROUND(`StrikePrice`, 4)                          AS close_price,
    ROW_NUMBER() OVER (PARTITION BY `TradeReportID`) AS rn
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report`,
  UNNEST(`Sides`) AS side
)
WHERE rn = 1
ORDER BY close_price DESC, trade_report_id
LIMIT 6;