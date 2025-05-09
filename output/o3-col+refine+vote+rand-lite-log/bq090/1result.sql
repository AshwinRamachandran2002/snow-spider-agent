SELECT
  AVG(CASE WHEN LOWER(p.PartyID) LIKE '%lucky%' THEN LastPx - StrikePrice END)
  - 
  AVG(CASE WHEN LOWER(p.PartyID) LIKE '%momo%'  THEN LastPx - StrikePrice END)
    AS diff_avg_intrinsic_value
FROM  `bigquery-public-data.cymbal_investments.trade_capture_report`,
      UNNEST(Sides) AS s,
      UNNEST(s.PartyIDs) AS p
WHERE s.Side = 'LONG';