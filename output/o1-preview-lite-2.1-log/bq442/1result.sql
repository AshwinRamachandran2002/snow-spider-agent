SELECT
  TradeReportID AS tradeID,
  MaturityDate AS tradeTimestamp,
  CASE
    WHEN SUBSTR(TargetCompID, 1, 4) = 'MOMO' THEN 'Momentum'
    WHEN SUBSTR(TargetCompID, 1, 4) = 'LUCK' THEN 'Feeling Lucky'
    WHEN SUBSTR(TargetCompID, 1, 4) = 'PRED' THEN 'Prediction'
    ELSE 'Unknown'
  END AS algorithm,
  Symbol AS symbol,
  CAST(ROUND(LastPx, 4) AS FLOAT64) AS openPrice,
  CAST(ROUND(StrikePrice, 4) AS FLOAT64) AS closePrice,
  s.Side AS tradeDirection,
  CASE
    WHEN s.Side = 'LONG' THEN 1
    WHEN s.Side = 'SHORT' THEN -1
    ELSE 0
  END AS tradeMultiplier
FROM
  `bigquery-public-data.cymbal_investments.trade_capture_report`,
  UNNEST(Sides) AS s
WHERE
  StrikePrice IS NOT NULL
ORDER BY
  StrikePrice DESC,
  TradeReportID ASC
LIMIT 6;