SELECT
  board_type,
  AVG(score) AS average_score
FROM (
  SELECT
    t.event_timestamp,
    MAX(IF(ep.key = 'board', ep.value.string_value, NULL)) AS board_type,
    MAX(IF(ep.key = 'value', ep.value.int_value, NULL)) AS score
  FROM `firebase-public-project.analytics_153293282.events_20180915` AS t,
  UNNEST(t.event_params) AS ep
  WHERE t.event_name = 'level_complete_quickplay'
  GROUP BY t.event_timestamp
)
WHERE board_type IS NOT NULL AND score IS NOT NULL
GROUP BY board_type;