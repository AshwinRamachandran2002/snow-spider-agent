WITH flat AS (
  SELECT
    StrikePrice - LastPx AS intrinsic_value,
    LOWER(party.PartyID)      AS partyid
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
  CROSS JOIN UNNEST(t.Sides)         AS side
  CROSS JOIN UNNEST(side.PartyIDs)   AS party
  WHERE side.Side = 'LONG'                         -- focus on long-side trades
),
avg_values AS (
  SELECT
    AVG(CASE WHEN partyid LIKE '%lucky%' THEN intrinsic_value END) AS avg_lucky,
    AVG(CASE WHEN partyid LIKE '%momo%'  THEN intrinsic_value END) AS avg_momo
  FROM flat
)
SELECT
  avg_lucky - avg_momo AS avg_intrinsic_diff_long_side
FROM avg_values;