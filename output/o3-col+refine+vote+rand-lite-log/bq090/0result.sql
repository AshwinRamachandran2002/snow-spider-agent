WITH stats AS (
  SELECT
    AVG(CASE WHEN LOWER(pid.PartyID) LIKE '%momo%' THEN ABS(t.`StrikePrice` - t.`LastPx`) END) AS avg_momentum,
    AVG(CASE WHEN LOWER(pid.PartyID) LIKE '%luck%' THEN ABS(t.`StrikePrice` - t.`LastPx`) END) AS avg_feeling_lucky
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t,
  UNNEST(t.`Sides`) AS s,
  UNNEST(s.PartyIDs) AS pid
  WHERE s.Side = 'LONG'
)
SELECT
  avg_feeling_lucky - avg_momentum AS diff_avg_intrinsic_value
FROM stats;