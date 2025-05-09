-- Average score per board type for quick‑play completions on 15‑Sep‑2018
WITH completions AS (
  SELECT
    MAX(CASE WHEN p.key = 'board' THEN p.value.string_value END) AS board_type,
    MAX(CASE WHEN p.key = 'value' THEN p.value.int_value END)   AS score
  FROM `firebase-public-project.analytics_153293282.events_20180915` AS t,
  UNNEST(t.event_params) AS p
  WHERE t.event_name = 'level_complete_quickplay'
  GROUP BY t.event_timestamp, t.user_pseudo_id
)
SELECT
  board_type,
  AVG(score) AS avg_score
FROM completions
GROUP BY board_type
ORDER BY avg_score DESC;