WITH long_side_trades AS (
  SELECT
    (StrikePrice - LastPx) * Quantity AS intrinsic_value,
    CASE
      WHEN REGEXP_CONTAINS(UPPER(TargetCompID), r'LUCKY') THEN 'feeling_lucky'
      WHEN REGEXP_CONTAINS(UPPER(TargetCompID), r'MOMO')  THEN 'momentum'
    END AS strategy
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report`,
       UNNEST(Sides) AS s
  WHERE UPPER(s.Side) = 'LONG'                      -- keep only long‑side trades
        AND (REGEXP_CONTAINS(UPPER(TargetCompID), r'LUCKY') 
             OR REGEXP_CONTAINS(UPPER(TargetCompID), r'MOMO'))   -- keep only the two strategies
),
avg_intrinsic AS (
  SELECT
    AVG(CASE WHEN strategy = 'feeling_lucky' THEN intrinsic_value END) AS avg_feeling_lucky,
    AVG(CASE WHEN strategy = 'momentum'      THEN intrinsic_value END) AS avg_momentum
  FROM long_side_trades
)
SELECT
  ROUND(avg_feeling_lucky - avg_momentum, 4) AS avg_intrinsic_value_difference
FROM avg_intrinsic;