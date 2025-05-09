WITH long_trades AS (
  SELECT
    CASE
      WHEN LOWER(p.PartyID) LIKE 'lucky%' THEN 'feeling_lucky'
      WHEN LOWER(p.PartyID) LIKE 'momo%'  THEN 'momentum'
    END                                   AS strategy,
    (t.StrikePrice - t.LastPx)            AS intrinsic_value
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
  CROSS JOIN UNNEST(t.Sides)    AS s
  CROSS JOIN UNNEST(s.PartyIDs) AS p
  WHERE s.Side = 'LONG'
    AND (LOWER(p.PartyID) LIKE 'lucky%' OR LOWER(p.PartyID) LIKE 'momo%')
)

SELECT
  ROUND(
    AVG(CASE WHEN strategy = 'feeling_lucky' THEN intrinsic_value END)
    -
    AVG(CASE WHEN strategy = 'momentum'      THEN intrinsic_value END)
  , 4) AS avg_intrinsic_value_difference
FROM long_trades;