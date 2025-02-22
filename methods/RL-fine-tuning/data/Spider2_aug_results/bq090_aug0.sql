-- Task: Calculate the difference, rounded to 4 decimal places, between the average intrinsic value (StrikePrice - LastPx) for long-side trades where the TargetCompID starts with 'lucky' and those where it starts with 'momo'.
SELECT
  ROUND(
    AVG(CASE WHEN LOWER(TargetCompID) LIKE 'lucky%' THEN (StrikePrice - LastPx) END) -
    AVG(CASE WHEN LOWER(TargetCompID) LIKE 'momo%' THEN (StrikePrice - LastPx) END),
    4
  ) AS higher
FROM `bigquery-public-data.cymbal_investments.trade_capture_report`,
     UNNEST(Sides) AS side
WHERE LOWER(side.Side) = 'long'
  AND (LOWER(TargetCompID) LIKE 'lucky%' OR LOWER(TargetCompID) LIKE 'momo%')