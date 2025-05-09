SELECT
  "TradeReportID" AS "tradeID",
  "TradeDate" AS "tradeTimestamp",
  CASE LEFT("TargetCompID", 4)
    WHEN 'MOMO' THEN 'Momentum'
    WHEN 'LUCK' THEN 'Feeling Lucky'
    WHEN 'PRED' THEN 'Prediction'
    ELSE 'Unknown'
  END AS "algorithm",
  "Symbol" AS "symbol",
  ROUND("StrikePrice", 4) AS "openPrice",
  ROUND("LastPx", 4) AS "closePrice",
  "Sides"[0]."Side"::STRING AS "tradeDirection",
  CASE "Sides"[0]."Side"::STRING
    WHEN 'SHORT' THEN -1
    WHEN 'LONG' THEN 1
    ELSE 0
  END AS "tradeMultiplier"
FROM CYMBAL_INVESTMENTS.CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
ORDER BY "closePrice" DESC NULLS LAST
LIMIT 6;