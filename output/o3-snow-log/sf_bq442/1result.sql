SELECT
    "OrderID"                                                      AS "tradeID",
    TO_TIMESTAMP_NTZ("MaturityDate" / 1000000)                     AS "tradeTimestamp",
    CASE
        WHEN LEFT("TargetCompID", 4) = 'MOMO' THEN 'Momentum'
        WHEN LEFT("TargetCompID", 4) = 'LUCK' THEN 'Feeling Lucky'
        WHEN LEFT("TargetCompID", 4) = 'PRED' THEN 'Prediction'
        ELSE 'Unknown'
    END                                                            AS "algorithm",
    "Symbol"                                                       AS "symbol",
    ROUND("LastPx", 4)                                             AS "openPrice",
    ROUND("StrikePrice", 4)                                        AS "closePrice",
    (s.value:"Side")::STRING                                       AS "tradeDirection",
    CASE
        WHEN (s.value:"Side")::STRING = 'SHORT' THEN -1
        WHEN (s.value:"Side")::STRING = 'LONG'  THEN  1
        ELSE 0
    END                                                            AS "tradeMultiplier"
FROM "CYMBAL_INVESTMENTS"."CYMBAL_INVESTMENTS"."TRADE_CAPTURE_REPORT",
     LATERAL FLATTEN(input => "Sides") s
ORDER BY "closePrice" DESC NULLS LAST
LIMIT 6;