SELECT
  t.OrderID                                                    AS tradeID,
  t.MaturityDate                                               AS tradeTimestamp,
  CASE
    WHEN STARTS_WITH(t.TargetCompID, 'MOMO') THEN 'Momentum'
    WHEN STARTS_WITH(t.TargetCompID, 'LUCK') THEN 'Feeling Lucky'
    WHEN STARTS_WITH(t.TargetCompID, 'PRED') THEN 'Prediction'
    ELSE 'Unknown'
  END                                                         AS algorithm,
  t.Symbol                                                     AS symbol,
  t.LastPx                                                     AS openPrice,
  t.StrikePrice                                                AS closePrice,
  s.Side                                                       AS tradeDirection,
  CASE
    WHEN s.Side = 'SHORT' THEN -1
    WHEN s.Side = 'LONG'  THEN  1
    ELSE NULL
  END                                                         AS tradeMultiplier
FROM
  `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
CROSS JOIN
  UNNEST(t.Sides) AS s
ORDER BY
  closePrice DESC,
  tradeID
LIMIT 6;