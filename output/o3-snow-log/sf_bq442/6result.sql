SELECT
    t."OrderID"                                  AS "tradeID",
    TO_TIMESTAMP_NTZ(t."MaturityDate" / 1000000) AS "tradeTimestamp",
    CASE
        WHEN SUBSTR(t."TargetCompID", 1, 4) = 'MOMO' THEN 'Momentum'
        WHEN SUBSTR(t."TargetCompID", 1, 4) = 'LUCK' THEN 'Feeling Lucky'
        WHEN SUBSTR(t."TargetCompID", 1, 4) = 'PRED' THEN 'Prediction'
        ELSE 'Unknown'
    END                                          AS "algorithm",
    t."Symbol"                                   AS "symbol",
    t."LastPx"                                   AS "openPrice",
    t."StrikePrice"                              AS "closePrice",
    s.value:"Side"::STRING                       AS "tradeDirection",
    CASE
        WHEN s.value:"Side"::STRING = 'SHORT' THEN -1
        WHEN s.value:"Side"::STRING = 'LONG'  THEN 1
        ELSE NULL
    END                                          AS "tradeMultiplier"
FROM "CYMBAL_INVESTMENTS"."CYMBAL_INVESTMENTS"."TRADE_CAPTURE_REPORT" t,
     LATERAL FLATTEN(INPUT => t."Sides") s
ORDER BY "closePrice" DESC NULLS LAST
LIMIT 6;