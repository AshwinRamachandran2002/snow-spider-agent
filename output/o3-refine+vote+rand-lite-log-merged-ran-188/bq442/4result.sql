SELECT
  TradeReportID                                            AS tradeID,
  MaturityDate                                             AS tradeTimestamp,
  CASE
      WHEN SUBSTR(TargetCompID, 1, 4) = 'MOMO' THEN 'Momentum'
      WHEN SUBSTR(TargetCompID, 1, 4) = 'LUCK' THEN 'Feeling Lucky'
      WHEN SUBSTR(TargetCompID, 1, 4) = 'PRED' THEN 'Prediction'
      ELSE 'Unknown'
  END                                                      AS algorithm,
  Symbol                                                   AS symbol,
  LastPx                                                   AS openPrice,
  StrikePrice                                              AS closePrice,
  (SELECT s.Side FROM UNNEST(Sides) AS s LIMIT 1)          AS tradeDirection,
  CASE
      WHEN (SELECT s.Side FROM UNNEST(Sides) AS s LIMIT 1) = 'SHORT' THEN -1
      WHEN (SELECT s.Side FROM UNNEST(Sides) AS s LIMIT 1) = 'LONG'  THEN  1
      ELSE 0
  END                                                      AS tradeMultiplier
FROM `bigquery-public-data.cymbal_investments.trade_capture_report`
ORDER BY closePrice DESC, tradeID
LIMIT 6;