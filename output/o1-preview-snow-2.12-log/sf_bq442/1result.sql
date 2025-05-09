SELECT
    t."TradeReportID" AS "tradeID",
    TO_TIMESTAMP_NTZ(t."TransactTime", 6) AS "tradeTimestamp",
    CASE
        WHEN SUBSTR(t."TargetCompID", 1, 4) = 'MOMO' THEN 'Momentum'
        WHEN SUBSTR(t."TargetCompID", 1, 4) = 'LUCK' THEN 'Feeling Lucky'
        WHEN SUBSTR(t."TargetCompID", 1, 4) = 'PRED' THEN 'Prediction'
        ELSE 'Unknown'
    END AS "algorithm",
    t."Symbol" AS "symbol",
    ROUND(t."LastPx", 4) AS "openPrice",
    ROUND(t."StrikePrice", 4) AS "closePrice",
    s.value:"Side"::STRING AS "tradeDirection",
    CASE
        WHEN s.value:"Side"::STRING = 'SHORT' THEN -1
        WHEN s.value:"Side"::STRING = 'LONG' THEN 1
        ELSE 0
    END AS "tradeMultiplier"
FROM
    CYMBAL_INVESTMENTS.CYMBAL_INVESTMENTS."TRADE_CAPTURE_REPORT" t,
    LATERAL FLATTEN(input => t."Sides") s
ORDER BY
    t."StrikePrice" DESC NULLS LAST,
    t."TradeReportID" ASC
LIMIT 6;