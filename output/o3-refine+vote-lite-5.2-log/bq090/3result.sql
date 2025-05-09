WITH exploded AS (
  -- Break the Sides array to reach the initiating‑trader prop‑code
  SELECT
    t.StrikePrice,
    t.LastPx,
    side.Side                         AS side_type,
    pid.PartyID                       AS party_id
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report` AS t
  CROSS JOIN UNNEST(t.Sides)        AS side
  CROSS JOIN UNNEST(side.PartyIDs)  AS pid
  WHERE pid.PartyRole = 'INITIATING TRADER'   -- the algo / strategy identifier
        AND side.Side = 'LONG'                -- only long‑side trades
),
tagged AS (
  -- Tag each trade with its strategy and compute intrinsic value
  SELECT
    CASE
      WHEN REGEXP_CONTAINS(LOWER(party_id), r'^momo')  THEN 'momentum'
      WHEN REGEXP_CONTAINS(LOWER(party_id), r'^lucky') THEN 'feeling-lucky'
      ELSE NULL
    END                                          AS strategy,
    StrikePrice - LastPx                         AS intrinsic_value
  FROM exploded
)
SELECT
  AVG(CASE WHEN strategy = 'feeling-lucky' THEN intrinsic_value END) -
  AVG(CASE WHEN strategy = 'momentum'      THEN intrinsic_value END) AS diff_avg_intrinsic_value
FROM tagged
WHERE strategy IN ('feeling-lucky', 'momentum');