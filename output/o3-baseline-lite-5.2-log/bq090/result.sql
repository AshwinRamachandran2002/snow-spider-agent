WITH long_side_trades AS (
  SELECT
    -- identify the strategy by the trader’s PartyID
    party.PartyID                         AS strategy_code,
    (t.StrikePrice - t.LastPx)            AS intrinsic_value
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
  CROSS JOIN UNNEST(t.Sides)  AS side
  CROSS JOIN UNNEST(side.PartyIDs) AS party
  WHERE side.Side = 'LONG'                              -- only long‑side trades
    AND party.PartyID IN ('LUCKYES', 'MOMOES')          -- feeling‑lucky vs. momentum
),
avg_intrinsic AS (
  SELECT
    strategy_code,
    AVG(intrinsic_value) AS avg_intrinsic_value
  FROM long_side_trades
  GROUP BY strategy_code
)
SELECT
  ROUND(
    MAX(CASE WHEN strategy_code = 'LUCKYES' THEN avg_intrinsic_value END) -
    MAX(CASE WHEN strategy_code = 'MOMOES' THEN avg_intrinsic_value END)
  , 4) AS avg_intrinsic_value_difference
FROM avg_intrinsic;