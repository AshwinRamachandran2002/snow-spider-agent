SELECT
  t.`OrderID`                                                    AS tradeID,
  t.`MaturityDate`                                               AS tradeTimestamp,
  CASE SUBSTR(t.`TargetCompID`, 1, 4)
       WHEN 'MOMO' THEN 'Momentum'
       WHEN 'LUCK' THEN 'Feeling Lucky'
       WHEN 'PRED' THEN 'Prediction'
  END                                                            AS algorithm,
  t.`Symbol`                                                     AS symbol,
  t.`LastPx`                                                     AS openPrice,
  t.`StrikePrice`                                                AS closePrice,
  s.Side                                                         AS tradeDirection,
  CASE s.Side
       WHEN 'SHORT' THEN -1
       WHEN 'LONG'  THEN  1
  END                                                            AS tradeMultiplier
FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
CROSS JOIN UNNEST(t.`Sides`) AS s
ORDER BY closePrice DESC, tradeTimestamp DESC
LIMIT 6;