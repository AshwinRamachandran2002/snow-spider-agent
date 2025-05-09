SELECT
  t.TradeReportID AS trade_report_id,
  t.MaturityDate  AS trade_timestamp,
  CASE
    WHEN SUBSTR(t.TargetCompID, 1, 4) = 'MOMO' THEN 'Momentum'
    WHEN SUBSTR(t.TargetCompID, 1, 4) = 'LUCK' THEN 'Feeling Lucky'
    WHEN SUBSTR(t.TargetCompID, 1, 4) = 'PRED' THEN 'Prediction'
    ELSE 'Unknown'
  END                                    AS algorithm,
  t.Symbol                               AS symbol,
  ROUND(t.LastPx,       4)               AS open_price,
  ROUND(t.StrikePrice,  4)               AS close_price,
  s.Side                                 AS trade_direction,
  CASE
    WHEN s.Side = 'SHORT' THEN -1
    WHEN s.Side = 'LONG'  THEN  1
    ELSE 0
  END                                    AS trade_multiplier
FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
CROSS JOIN UNNEST(t.Sides) AS s
WHERE t.StrikePrice IS NOT NULL
QUALIFY ROW_NUMBER() OVER (ORDER BY t.StrikePrice DESC, t.TradeReportID) <= 6;