WITH trades AS (
    SELECT
        "OrderID"                                   AS "tradeID",
        TO_TIMESTAMP_LTZ("MaturityDate" / 1e6)      AS "tradeTimestamp",
        CASE
            WHEN SUBSTR("TargetCompID", 1, 4) = 'MOMO' THEN 'Momentum'
            WHEN SUBSTR("TargetCompID", 1, 4) = 'LUCK' THEN 'Feeling Lucky'
            WHEN SUBSTR("TargetCompID", 1, 4) = 'PRED' THEN 'Prediction'
            ELSE 'Unknown'
        END                                         AS "algorithm",
        "Symbol"                                    AS "symbol",
        ROUND("LastPx",     4)                      AS "openPrice",
        ROUND("StrikePrice", 4)                     AS "closePrice",
        dir.value:"Side"::STRING                    AS "tradeDirection",
        CASE
            WHEN dir.value:"Side"::STRING = 'SHORT' THEN -1
            WHEN dir.value:"Side"::STRING = 'LONG'  THEN  1
            ELSE NULL
        END                                         AS "tradeMultiplier"
    FROM CYMBAL_INVESTMENTS.CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT,
         LATERAL FLATTEN(input => "Sides") dir
)
SELECT *
FROM trades
ORDER BY "closePrice" DESC NULLS LAST
LIMIT 6;