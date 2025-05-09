SELECT
  t.`OrderID`      AS `tradeID`,
  t.`MaturityDate` AS `tradeTimestamp`,
  CASE SUBSTR(t.`TargetCompID`, 1, 4)
       WHEN 'MOMO' THEN 'Momentum'
       WHEN 'LUCK' THEN 'Feeling Lucky'
       WHEN 'PRED' THEN 'Prediction'
       ELSE 'Unknown'
  END              AS `algorithm`,
  t.`Symbol`       AS `symbol`,
  t.`LastPx`       AS `openPrice`,
  t.`StrikePrice`  AS `closePrice`,
  sd.`Side`        AS `tradeDirection`,
  CASE sd.`Side`
       WHEN 'SHORT' THEN -1
       WHEN 'LONG'  THEN  1
  END              AS `tradeMultiplier`
FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
LEFT JOIN UNNEST(t.`Sides`) AS sd
ORDER BY `closePrice` DESC
LIMIT 6;