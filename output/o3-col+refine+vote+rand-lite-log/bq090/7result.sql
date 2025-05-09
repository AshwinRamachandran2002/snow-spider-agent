WITH avg_intrinsic AS (
  SELECT
    AVG(CASE WHEN REGEXP_CONTAINS(LOWER(pid.PartyID), r'lucky') THEN t.LastPx - t.StrikePrice END) AS lucky_avg,
    AVG(CASE WHEN REGEXP_CONTAINS(LOWER(pid.PartyID), r'momo|momentum') THEN t.LastPx - t.StrikePrice END) AS momentum_avg
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
  CROSS JOIN UNNEST(t.Sides) AS s
  CROSS JOIN UNNEST(s.PartyIDs) AS pid
  WHERE s.Side = 'LONG'
)
SELECT
  lucky_avg - momentum_avg AS intrinsic_value_difference
FROM avg_intrinsic;