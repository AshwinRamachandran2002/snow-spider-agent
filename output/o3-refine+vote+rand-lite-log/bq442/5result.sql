WITH parsed_trades AS (
  SELECT
    -- 1. Unique identifier for the trade
    t.OrderID                                             AS tradeID,

    -- 2. Maturity date of the trade
    t.MaturityDate                                        AS tradeTimestamp,

    -- 3. Algorithm derived from the first four characters of TargetCompID
    CASE
      WHEN SUBSTR(t.TargetCompID, 1, 4) = 'MOMO' THEN 'Momentum'
      WHEN SUBSTR(t.TargetCompID, 1, 4) = 'LUCK' THEN 'Feeling Lucky'
      WHEN SUBSTR(t.TargetCompID, 1, 4) = 'PRED' THEN 'Prediction'
      ELSE 'Unknown'
    END                                                   AS algorithm,

    -- 4. Trading symbol
    t.Symbol                                              AS symbol,

    -- 5. Opening price (rounded to 4 decimals)
    ROUND(t.LastPx, 4)                                    AS openPrice,

    -- 6. Closing price (rounded to 4 decimals)
    ROUND(t.StrikePrice, 4)                               AS closePrice,

    -- 7. Trade direction from nested Sides array
    s.Side                                                AS tradeDirection,

    -- 8. Multiplier derived from direction
    CASE
      WHEN s.Side = 'SHORT' THEN -1
      WHEN s.Side = 'LONG'  THEN  1
      ELSE NULL
    END                                                   AS tradeMultiplier
  FROM
    `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
  CROSS JOIN
    UNNEST(t.Sides) AS s
)

SELECT *
FROM parsed_trades
ORDER BY
  closePrice DESC,  -- primary sort: highest closing prices
  tradeID           -- secondary sort to ensure deterministic ordering
LIMIT 6;