WITH exploded AS (
  SELECT
    CASE
      WHEN REGEXP_CONTAINS(pid.PartyID, r'(?i)LCKY') THEN 'feeling-lucky'
      WHEN REGEXP_CONTAINS(pid.PartyID, r'(?i)MOMO') THEN 'momentum'
      ELSE NULL
    END                                                        AS strategy,
    (t.LastPx - t.StrikePrice) * t.Quantity                    AS intrinsic_value
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
  CROSS JOIN UNNEST(t.Sides)      AS s
  CROSS JOIN UNNEST(s.PartyIDs)   AS pid
  WHERE s.Side = 'LONG'
),
avg_values AS (
  SELECT
    strategy,
    AVG(intrinsic_value) AS avg_intrinsic_value
  FROM exploded
  WHERE strategy IN ('feeling-lucky', 'momentum')
  GROUP BY strategy
)
SELECT
  ROUND(
    (SELECT avg_intrinsic_value FROM avg_values WHERE strategy = 'feeling-lucky') -
    (SELECT avg_intrinsic_value FROM avg_values WHERE strategy = 'momentum'),
    4
  ) AS avg_intrinsic_value_difference;