SELECT
  board_type,
  AVG(score) AS average_score
FROM (
  SELECT
    MAX(CASE WHEN ep.key IN ('board', 'level', 'level_name') THEN ep.value.string_value END) AS board_type,
    MAX(CASE WHEN ep.key IN ('score', 'value') THEN CAST(ep.value.int_value AS FLOAT64) END) AS score
  FROM `firebase-public-project.analytics_153293282.events_20180915` AS t,
       UNNEST(t.event_params) AS ep
  WHERE t.event_name = 'level_complete_quickplay'
  GROUP BY t.event_timestamp, t.user_pseudo_id
)
WHERE board_type IS NOT NULL AND score IS NOT NULL
GROUP BY board_type;