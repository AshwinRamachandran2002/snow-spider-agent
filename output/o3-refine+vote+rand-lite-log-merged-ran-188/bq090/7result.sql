WITH long_side_trades AS (
  SELECT
    (StrikePrice - LastPx) * Quantity AS intrinsic_value,
    CASE
      WHEN LOWER(pid.PartyID) LIKE '%lucky%' THEN 'feeling_lucky'
      WHEN LOWER(pid.PartyID) LIKE '%momo%'  THEN 'momentum'
    END AS strategy
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` t
  CROSS JOIN UNNEST(t.Sides) AS s
  CROSS JOIN UNNEST(s.PartyIDs) AS pid
  WHERE s.Side = 'LONG'
    AND (LOWER(pid.PartyID) LIKE '%lucky%' OR LOWER(pid.PartyID) LIKE '%momo%')
),
avg_intrinsic AS (
  SELECT
    strategy,
    AVG(intrinsic_value) AS avg_intrinsic_value
  FROM long_side_trades
  GROUP BY strategy
)
SELECT
  (SELECT avg_intrinsic_value FROM avg_intrinsic WHERE strategy = 'feeling_lucky')
  -
  (SELECT avg_intrinsic_value FROM avg_intrinsic WHERE strategy = 'momentum')
  AS avg_intrinsic_value_difference;