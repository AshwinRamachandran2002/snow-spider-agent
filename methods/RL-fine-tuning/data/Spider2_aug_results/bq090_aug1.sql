-- Task: What is the average intrinsic value for trades using the feeling-lucky strategy under long-side trades?
SELECT
  ROUND(AVG(StrikePrice - LastPx), 4) AS average_intrinsic_value
FROM `bigquery-public-data.cymbal_investments.trade_capture_report`,
     UNNEST(Sides) AS side
WHERE LOWER(side.Side) = 'long'
  AND LOWER(TargetCompID) LIKE 'lucky%'