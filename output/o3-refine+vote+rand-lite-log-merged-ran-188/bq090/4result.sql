WITH long_side_trades AS (
  /* explode the arrays and keep only LONG‑side legs that carry the STRATEGY tag */
  SELECT
    UPPER(p.PartyID)                         AS strategy,
    (t.StrikePrice - t.LastPx)               AS intrinsic_value      -- close − entry
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
  CROSS JOIN UNNEST(t.Sides)      AS s
  CROSS JOIN UNNEST(s.PartyIDs)   AS p
  WHERE s.Side        = 'LONG'                        -- long‑side trades only
    AND p.PartyRole   = 'STRATEGY'                    -- element that tells us the strategy
    AND UPPER(p.PartyID) IN ('FEELING-LUCKY','MOMENTUM')
),

avg_by_strategy AS (
  SELECT
    AVG(CASE WHEN strategy = 'FEELING-LUCKY' THEN intrinsic_value END) AS avg_feeling_lucky,
    AVG(CASE WHEN strategy = 'MOMENTUM'      THEN intrinsic_value END) AS avg_momentum
  FROM long_side_trades
)

SELECT
  avg_feeling_lucky - avg_momentum          AS avg_intrinsic_value_difference
FROM  avg_by_strategy;