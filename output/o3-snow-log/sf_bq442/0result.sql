WITH trades AS (
    SELECT
        "OrderID"                                                  AS tradeID,
        TO_TIMESTAMP("MaturityDate" / 1000000)                    AS tradeTimestamp, -- convert µs-epoch to TIMESTAMP
        CASE
            WHEN LEFT("TargetCompID", 4) = 'MOMO' THEN 'Momentum'
            WHEN LEFT("TargetCompID", 4) = 'LUCK' THEN 'Feeling Lucky'
            WHEN LEFT("TargetCompID", 4) = 'PRED' THEN 'Prediction'
            ELSE 'Unknown'
        END                                                       AS algorithm,
        "Symbol"                                                   AS symbol,
        "LastPx"                                                   AS openPrice,
        "StrikePrice"                                              AS closePrice,
        s.value:"Side"::STRING                                     AS tradeDirection,
        CASE
            WHEN s.value:"Side"::STRING = 'SHORT' THEN -1
            WHEN s.value:"Side"::STRING = 'LONG'  THEN  1
            ELSE NULL
        END                                                       AS tradeMultiplier
    FROM CYMBAL_INVESTMENTS.CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT,
         LATERAL FLATTEN(INPUT => "Sides") s                       -- extract nested Side information
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
FROM trades
ORDER BY closePrice DESC NULLS LAST
LIMIT 6;