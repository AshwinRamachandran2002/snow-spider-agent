-- Top 6 trades with the highest closing (Strike) prices and all requested fields
SELECT
  t.TradeReportID AS tradeID,
  t.MaturityDate  AS tradeTimestamp,
  CASE
    WHEN LEFT(t.TargetCompID, 4) = 'MOMO' THEN 'Momentum'
    WHEN LEFT(t.TargetCompID, 4) = 'LUCK' THEN 'Feeling Lucky'
    WHEN LEFT(t.TargetCompID, 4) = 'PRED' THEN 'Prediction'
    ELSE 'Other'
  END             AS algorithm,
  t.Symbol,
  t.LastPx        AS openPrice,
  t.StrikePrice   AS closePrice,
  s.Side          AS tradeDirection,
  CASE
    WHEN s.Side = 'SHORT' THEN -1
    WHEN s.Side = 'LONG'  THEN  1
  END             AS tradeMultiplier
FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
CROSS JOIN UNNEST(t.Sides) AS s
ORDER BY closePrice DESC
LIMIT 6;