SELECT
  ROUND(
    AVG(CASE WHEN LOWER(p.PartyID) LIKE 'lucky%' THEN StrikePrice - LastPx END) -
    AVG(CASE WHEN LOWER(p.PartyID) LIKE 'momo%'  THEN StrikePrice - LastPx END)
  , 4) AS average_intrinsic_value_difference
FROM `bigquery-public-data.cymbal_investments.trade_capture_report`,
UNNEST(Sides) AS s,
UNNEST(s.PartyIDs) AS p
WHERE s.Side = 'LONG';