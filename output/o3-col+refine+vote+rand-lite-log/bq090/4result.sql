-- Difference in average intrinsic value (feeling-lucky – momentum) for LONG trades
SELECT
  AVG(IF(strategy = 'feeling-lucky', intrinsic_value, NULL))
  - AVG(IF(strategy = 'momentum',      intrinsic_value, NULL)) AS intrinsic_value_difference
FROM (
  SELECT
    CASE
      WHEN LOWER(t.TargetCompID) LIKE '%luck%' THEN 'feeling-lucky'
      WHEN LOWER(t.TargetCompID) LIKE '%momo%' THEN 'momentum'
    END AS strategy,
    t.StrikePrice - t.LastPx AS intrinsic_value
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t,
       UNNEST(t.Sides) AS s
  WHERE s.Side = 'LONG'
)
WHERE strategy IS NOT NULL;