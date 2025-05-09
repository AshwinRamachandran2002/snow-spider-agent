SELECT
  ROUND(
    AVG(CASE WHEN LOWER(party.PartyID) LIKE '%lucky%' THEN ABS(t.StrikePrice - t.LastPx) END) -
    AVG(CASE WHEN LOWER(party.PartyID) LIKE '%momo%' THEN ABS(t.StrikePrice - t.LastPx) END),
    4
  ) AS higher
FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t,
UNNEST(t.Sides) AS side,
UNNEST(side.PartyIDs) AS party
WHERE side.Side = 'LONG'
  AND (LOWER(party.PartyID) LIKE '%lucky%' OR LOWER(party.PartyID) LIKE '%momo%')