WITH long_trades AS (
  SELECT
    t.StrikePrice - t.LastPx AS intrinsic_value,
    LOWER(p.PartyID)         AS party_id
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
  CROSS JOIN UNNEST(t.Sides)    AS s
  CROSS JOIN UNNEST(s.PartyIDs) AS p
  WHERE s.Side = 'LONG'
),
averages AS (
  SELECT
    AVG(CASE WHEN party_id LIKE '%luck%' THEN intrinsic_value END) AS avg_lucky,
    AVG(CASE WHEN party_id LIKE '%momo%' THEN intrinsic_value END) AS avg_momentum
  FROM long_trades
)
SELECT
  ROUND(avg_lucky - avg_momentum, 4) AS average_intrinsic_value_difference
FROM averages;