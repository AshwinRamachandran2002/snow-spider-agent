-- Difference in average intrinsic value (close – entry) for LONG‑side trades
-- between “feeling‑lucky” and “momentum” strategies
WITH long_side AS (
  SELECT
    (t.StrikePrice - t.LastPx) * t.Quantity AS intrinsic_value,           -- intrinsic value per trade
    LOWER(pid.PartyID)                           AS party_id
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` t
  CROSS JOIN UNNEST(t.Sides)   AS s
  CROSS JOIN UNNEST(s.PartyIDs) AS pid
  WHERE s.Side = 'LONG'                     -- only long‑side trades
    AND pid.PartyRole = 'INITIATING TRADER' -- identify the trader / strategy
),
labeled AS (
  SELECT
    intrinsic_value,
    CASE
      WHEN party_id LIKE '%lucky%' THEN 'feeling_lucky'
      WHEN party_id LIKE '%momo%'  THEN 'momentum'
    END AS strategy
  FROM long_side
  WHERE party_id LIKE '%lucky%' OR party_id LIKE '%momo%'  -- keep the two strategies of interest
),
avg_vals AS (
  SELECT
    AVG(CASE WHEN strategy = 'feeling_lucky' THEN intrinsic_value END) AS avg_feeling_lucky,
    AVG(CASE WHEN strategy = 'momentum'     THEN intrinsic_value END) AS avg_momentum
  FROM labeled
)
SELECT
  avg_feeling_lucky - avg_momentum AS avg_intrinsic_value_diff
FROM avg_vals;