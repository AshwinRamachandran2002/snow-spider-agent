WITH enriched_trades AS (
  SELECT
    -- 1. Unique identifier of the order
    t.`OrderID`                                     AS tradeID,
    
    -- 2. Timestamp when the trade is due
    t.`MaturityDate`                                AS tradeTimestamp,
    
    -- 3. Trading algorithm inferred from the first four characters of TargetCompID
    CASE SUBSTR(t.`TargetCompID`, 1, 4)
      WHEN 'MOMO' THEN 'Momentum'
      WHEN 'LUCK' THEN 'Feeling Lucky'
      WHEN 'PRED' THEN 'Prediction'
      ELSE 'Unknown'
    END                                             AS algorithm,
    
    -- 4. Trading symbol
    t.`Symbol`                                      AS symbol,
    
    -- 5. Opening price (rounded to four decimals)
    ROUND(t.`LastPx`,   4)                          AS openPrice,
    
    -- 6. Closing price (rounded to four decimals)
    ROUND(t.`StrikePrice`, 4)                       AS closePrice,
    
    -- 7. Trade direction extracted from nested Sides array
    s.Side                                          AS tradeDirection,
    
    -- 8. Multiplier derived from direction
    CASE s.Side
      WHEN 'SHORT' THEN -1
      WHEN 'LONG'  THEN  1
      ELSE NULL
    END                                             AS tradeMultiplier
  FROM
    `bigquery-public-data.cymbal_investments.trade_capture_report` AS t,
    UNNEST(t.`Sides`) AS s
)

SELECT *
FROM enriched_trades
ORDER BY closePrice DESC, tradeID
LIMIT 6;