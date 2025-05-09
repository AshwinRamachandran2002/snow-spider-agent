WITH long_side_trades AS (
  SELECT
    t.TradeReportID,
    s.Side,
    p.PartyID,
    -- intrinsic value for a long position: closing price minus entry price
    (t.StrikePrice - t.LastPx) AS intrinsic_value
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
  CROSS JOIN UNNEST(t.Sides) AS s
  CROSS JOIN UNNEST(s.PartyIDs) AS p
  WHERE s.Side = 'LONG'                      -- only long‐side trades
),
classified AS (
  SELECT
    CASE
      WHEN REGEXP_CONTAINS(PartyID, r'(?i)lucky') THEN 'feeling_lucky'
      WHEN REGEXP_CONTAINS(PartyID, r'(?i)momo')  THEN 'momentum'
      ELSE NULL
    END AS strategy,
    intrinsic_value
  FROM long_side_trades
  WHERE intrinsic_value IS NOT NULL
)
SELECT
  AVG(IF(strategy = 'feeling_lucky', intrinsic_value, NULL))
  - AVG(IF(strategy = 'momentum',     intrinsic_value, NULL)) AS avg_intrinsic_value_difference
FROM classified
WHERE strategy IN ('feeling_lucky', 'momentum');