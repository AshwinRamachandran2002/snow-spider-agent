SELECT
  ROUND(
    AVG(CASE WHEN LOWER(p.PartyID) LIKE '%luck%' THEN t.StrikePrice - t.LastPx END) -
    AVG(CASE WHEN LOWER(p.PartyID) LIKE '%momo%' THEN t.StrikePrice - t.LastPx END)
  , 4) AS average_intrinsic_value_difference
FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t,
     UNNEST(t.Sides)    AS s,
     UNNEST(s.PartyIDs) AS p
WHERE s.Side = 'LONG'
  AND (LOWER(p.PartyID) LIKE '%momo%' OR LOWER(p.PartyID) LIKE '%luck%');