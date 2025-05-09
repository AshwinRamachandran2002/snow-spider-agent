SELECT
  t.`OrderID`                                                                     AS tradeID,
  t.`MaturityDate`                                                                AS tradeTimestamp,
  CASE
    WHEN SUBSTR(t.`TargetCompID`, 1, 4) = 'MOMO' THEN 'Momentum'
    WHEN SUBSTR(t.`TargetCompID`, 1, 4) = 'LUCK' THEN 'Feeling Lucky'
    WHEN SUBSTR(t.`TargetCompID`, 1, 4) = 'PRED' THEN 'Prediction'
    ELSE 'Unknown'
  END                                                                              AS algorithm,
  t.`Symbol`                                                                       AS symbol,
  ROUND(t.`LastPx`,     4)                                                         AS openPrice,
  ROUND(t.`StrikePrice`, 4)                                                        AS closePrice,
  s.Side                                                                           AS tradeDirection,
  CASE
    WHEN s.Side = 'SHORT' THEN -1
    WHEN s.Side = 'LONG'  THEN  1
    ELSE NULL
  END                                                                              AS tradeMultiplier
FROM
  `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
CROSS JOIN
  UNNEST(t.`Sides`) AS s
ORDER BY
  closePrice DESC,
  tradeTimestamp DESC
LIMIT 6;