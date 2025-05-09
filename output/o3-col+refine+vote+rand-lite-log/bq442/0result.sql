-- Top-6 trade reports with the highest closing prices
SELECT
  t.OrderID                                         AS tradeID,
  t.MaturityDate                                    AS tradeTimestamp,
  CASE
    WHEN SUBSTR(t.TargetCompID, 1, 4) = 'MOMO' THEN 'Momentum'
    WHEN SUBSTR(t.TargetCompID, 1, 4) = 'LUCK' THEN 'Feeling Lucky'
    WHEN SUBSTR(t.TargetCompID, 1, 4) = 'PRED' THEN 'Prediction'
    ELSE 'Other'
  END                                               AS algorithm,
  t.Symbol                                          AS symbol,
  t.LastPx                                          AS openPrice,
  t.StrikePrice                                     AS closePrice,
  s.Side                                            AS tradeDirection,
  CASE
    WHEN s.Side = 'SHORT' THEN -1
    WHEN s.Side = 'LONG'  THEN  1
  END                                               AS tradeMultiplier
FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
CROSS JOIN UNNEST(t.Sides) AS s
ORDER BY closePrice DESC
LIMIT 6;