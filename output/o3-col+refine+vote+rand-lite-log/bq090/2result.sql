WITH long_trades AS (
  SELECT
    CASE
      WHEN LOWER(TargetCompID) LIKE '%luck%' THEN 'feeling-lucky'
      WHEN LOWER(TargetCompID) LIKE '%mom%'  THEN 'momentum'
    END AS strategy,
    StrikePrice - LastPx AS intrinsic_value
  FROM
    `bigquery-public-data.cymbal_investments.trade_capture_report`,
    UNNEST(Sides) AS side
  WHERE
    side.Side = 'LONG'
    AND (LOWER(TargetCompID) LIKE '%luck%' OR LOWER(TargetCompID) LIKE '%mom%')
),
avgs AS (
  SELECT
    strategy,
    AVG(intrinsic_value) AS avg_intrinsic_value
  FROM long_trades
  GROUP BY strategy
)
SELECT
  (SELECT avg_intrinsic_value FROM avgs WHERE strategy = 'feeling-lucky')
  -
  (SELECT avg_intrinsic_value FROM avgs WHERE strategy = 'momentum')
  AS intrinsic_value_difference;