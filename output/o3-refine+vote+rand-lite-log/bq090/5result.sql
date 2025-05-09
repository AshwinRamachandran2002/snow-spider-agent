WITH classified_trades AS (
  SELECT
    (StrikePrice - LastPx) * Quantity AS intrinsic_value,
    CASE
      WHEN REGEXP_CONTAINS(TargetCompID, r'(?i)LUCK') THEN 'feeling_lucky'
      WHEN REGEXP_CONTAINS(TargetCompID, r'(?i)MOMO') THEN 'momentum'
      ELSE NULL
    END AS strategy
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
  -- keep only long‑side trades
  WHERE EXISTS (
    SELECT 1
    FROM UNNEST(t.Sides) s
    WHERE s.Side = 'LONG'
  )
)
SELECT
  AVG(IF(strategy = 'feeling_lucky', intrinsic_value, NULL))
  - 
  AVG(IF(strategy = 'momentum',      intrinsic_value, NULL)) AS intrinsic_value_difference
FROM classified_trades
WHERE strategy IN ('feeling_lucky', 'momentum');