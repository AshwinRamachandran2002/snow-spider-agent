SELECT
  `TradeReportID` AS trade_report_id,
  FORMAT('%.4f', `StrikePrice`) AS close_price
FROM `bigquery-public-data.cymbal_investments.trade_capture_report`
ORDER BY `StrikePrice` DESC, `TradeReportID`
LIMIT 6;