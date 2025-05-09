SELECT
  AVG(IF(LOWER(`TargetCompID`) LIKE '%luck%', `LastPx` - `StrikePrice`, NULL))
  -
  AVG(IF(LOWER(`TargetCompID`) LIKE '%momo%', `LastPx` - `StrikePrice`, NULL)) 
    AS avg_intrinsic_value_difference
FROM `bigquery-public-data.cymbal_investments.trade_capture_report`
WHERE EXISTS (SELECT 1 FROM UNNEST(`Sides`) s WHERE s.Side = 'LONG')
  AND (LOWER(`TargetCompID`) LIKE '%luck%' OR LOWER(`TargetCompID`) LIKE '%momo%');