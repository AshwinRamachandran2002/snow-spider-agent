SELECT
    t."OrderID"                                         AS "tradeID",
    TO_TIMESTAMP_LTZ(t."MaturityDate" / 1000000)        AS "tradeTimestamp",
    CASE UPPER(SUBSTR(t."TargetCompID", 1, 4))
        WHEN 'MOMO' THEN 'Momentum'
        WHEN 'LUCK' THEN 'Feeling Lucky'
        WHEN 'PRED' THEN 'Prediction'
        ELSE 'Unknown'
    END                                                 AS "algorithm",
    t."Symbol"                                          AS "symbol",
    t."LastPx"                                          AS "openPrice",
    t."StrikePrice"                                     AS "closePrice",
    f.value:"Side"::STRING                              AS "tradeDirection",
    CASE f.value:"Side"::STRING
        WHEN 'SHORT' THEN -1
        WHEN 'LONG'  THEN 1
        ELSE NULL
    END                                                 AS "tradeMultiplier"
FROM CYMBAL_INVESTMENTS.CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT AS t,
     LATERAL FLATTEN(input => t."Sides") AS f
ORDER BY t."StrikePrice" DESC NULLS LAST
LIMIT 6;