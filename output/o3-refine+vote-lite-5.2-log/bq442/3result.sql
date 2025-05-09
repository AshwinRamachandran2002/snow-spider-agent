WITH parsed AS (
  SELECT
    t.OrderID                                               AS tradeID,
    t.MaturityDate                                          AS tradeTimestamp,
    CASE
      WHEN SUBSTR(t.TargetCompID, 1, 4) = 'MOMO' THEN 'Momentum'
      WHEN SUBSTR(t.TargetCompID, 1, 4) = 'LUCK' THEN 'Feeling Lucky'
      WHEN SUBSTR(t.TargetCompID, 1, 4) = 'PRED' THEN 'Prediction'
      ELSE 'Unknown'
    END                                                    AS algorithm,
    t.Symbol                                                AS symbol,
    t.LastPx                                                AS openPrice,
    t.StrikePrice                                           AS closePrice,
    s.Side                                                  AS tradeDirection,
    CASE
      WHEN s.Side = 'SHORT' THEN -1
      WHEN s.Side = 'LONG'  THEN  1
    END                                                    AS tradeMultiplier,
    ROW_NUMBER() OVER (PARTITION BY t.OrderID ORDER BY s.Side) AS rn
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` t
  LEFT JOIN UNNEST(t.Sides) AS s
)
SELECT
  tradeID,
  tradeTimestamp,
  algorithm,
  symbol,
  openPrice,
  closePrice,
  tradeDirection,
  tradeMultiplier
FROM parsed
WHERE rn = 1
ORDER BY closePrice DESC, tradeID
LIMIT 6;