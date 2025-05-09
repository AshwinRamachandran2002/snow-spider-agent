SELECT
  `TradeReportID` AS tradeID,
  `MaturityDate`  AS tradeTimestamp,
  CASE
    WHEN SUBSTR(`TargetCompID`, 1, 4) = 'MOMO' THEN 'Momentum'
    WHEN SUBSTR(`TargetCompID`, 1, 4) = 'LUCK' THEN 'Feeling Lucky'
    WHEN SUBSTR(`TargetCompID`, 1, 4) = 'PRED' THEN 'Prediction'
    ELSE 'Other'
  END             AS algorithm,
  `Symbol`        AS symbol,
  `LastPx`        AS openPrice,
  `StrikePrice`   AS closePrice,
  s.Side          AS tradeDirection,
  CASE
    WHEN s.Side = 'SHORT' THEN -1
    WHEN s.Side = 'LONG'  THEN  1
  END             AS tradeMultiplier
FROM `bigquery-public-data.cymbal_investments.trade_capture_report`,
UNNEST(`Sides`) AS s
ORDER BY `StrikePrice` DESC, `TradeReportID`
LIMIT 6;