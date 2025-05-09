SELECT
  `TradeReportID` AS `tradeID`,
  `TransactTime` AS `tradeTimestamp`,
  CASE
    WHEN SUBSTR(`TargetCompID`, 1, 4) = 'MOMO' THEN 'Momentum'
    WHEN SUBSTR(`TargetCompID`, 1, 4) = 'LUCK' THEN 'Feeling Lucky'
    WHEN SUBSTR(`TargetCompID`, 1, 4) = 'PRED' THEN 'Prediction'
    ELSE 'Unknown'
  END AS `algorithm`,
  `Symbol` AS `symbol`,
  ROUND(`LastPx`, 4) AS `openPrice`,
  ROUND(`StrikePrice`, 4) AS `closePrice`,
  `Sides`.`Side` AS `tradeDirection`,
  CASE
    WHEN `Sides`.`Side` = 'LONG' THEN 1
    WHEN `Sides`.`Side` = 'SHORT' THEN -1
    ELSE 0
  END AS `tradeMultiplier`
FROM
  `bigquery-public-data.cymbal_investments.trade_capture_report`,
  UNNEST(`Sides`) AS `Sides`
ORDER BY
  `closePrice` DESC
LIMIT 6;