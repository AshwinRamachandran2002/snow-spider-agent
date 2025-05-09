SELECT
  "OrderID"                                                                AS "tradeID",
  TO_TIMESTAMP_LTZ("MaturityDate" / 1000000)                               AS "tradeTimestamp",
  CASE
      WHEN SUBSTR("TargetCompID", 1, 4) = 'MOMO' THEN 'Momentum'
      WHEN SUBSTR("TargetCompID", 1, 4) = 'LUCK' THEN 'Feeling Lucky'
      WHEN SUBSTR("TargetCompID", 1, 4) = 'PRED' THEN 'Prediction'
      ELSE 'Unknown'
  END                                                                      AS "algorithm",
  "Symbol"                                                                 AS "symbol",
  "LastPx"                                                                 AS "openPrice",
  "StrikePrice"                                                            AS "closePrice",
  "Sides"[0]:"Side"::STRING                                                AS "tradeDirection",
  CASE
      WHEN "Sides"[0]:"Side"::STRING = 'SHORT' THEN -1
      WHEN "Sides"[0]:"Side"::STRING = 'LONG'  THEN  1
      ELSE 0
  END                                                                      AS "tradeMultiplier"
FROM CYMBAL_INVESTMENTS.CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
ORDER BY "closePrice" DESC NULLS LAST
LIMIT 6;