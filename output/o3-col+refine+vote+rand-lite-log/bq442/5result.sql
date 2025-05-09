SELECT
  tr.OrderID AS tradeID,
  tr.MaturityDate AS tradeTimestamp,
  CASE SUBSTR(tr.TargetCompID, 1, 4)
    WHEN 'MOMO' THEN 'Momentum'
    WHEN 'LUCK' THEN 'Feeling Lucky'
    WHEN 'PRED' THEN 'Prediction'
    ELSE 'Unknown'
  END AS algorithm,
  tr.Symbol AS symbol,
  tr.LastPx AS openPrice,
  tr.StrikePrice AS closePrice,
  s.Side AS tradeDirection,
  CASE
    WHEN s.Side = 'SHORT' THEN -1
    WHEN s.Side = 'LONG'  THEN  1
  END AS tradeMultiplier
FROM
  `bigquery-public-data.cymbal_investments.trade_capture_report` AS tr,
  UNNEST(tr.Sides) AS s
ORDER BY
  closePrice DESC
LIMIT 6;