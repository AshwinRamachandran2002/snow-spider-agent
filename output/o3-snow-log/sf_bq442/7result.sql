SELECT
    "OrderID"                                                        AS "tradeID",
    TO_TIMESTAMP_LTZ("MaturityDate" / 1000000)                       AS "tradeTimestamp",
    CASE LEFT("TargetCompID", 4)
         WHEN 'MOMO' THEN 'Momentum'
         WHEN 'LUCK' THEN 'Feeling Lucky'
         WHEN 'PRED' THEN 'Prediction'
         ELSE 'Unknown'
    END                                                              AS "algorithm",
    "Symbol"                                                         AS "symbol",
    ROUND("LastPx",       4)                                         AS "openPrice",
    ROUND("StrikePrice",  4)                                         AS "closePrice",
    UPPER(("Sides"[0]:"Side")::STRING)                               AS "tradeDirection",
    CASE UPPER(("Sides"[0]:"Side")::STRING)
         WHEN 'SHORT' THEN -1
         WHEN 'LONG'  THEN  1
         ELSE NULL
    END                                                              AS "tradeMultiplier"
FROM
    "CYMBAL_INVESTMENTS"."CYMBAL_INVESTMENTS"."TRADE_CAPTURE_REPORT"
ORDER BY
    "closePrice" DESC NULLS LAST
LIMIT 6;