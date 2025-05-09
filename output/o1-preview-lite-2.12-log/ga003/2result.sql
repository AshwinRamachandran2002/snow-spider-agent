SELECT
  board AS Board_Type,
  AVG(score) AS Average_Score
FROM (
  SELECT
    t.event_timestamp,
    MAX(CASE WHEN ep.key = 'board' THEN ep.value.string_value END) AS board,
    MAX(CASE WHEN ep.key = 'value' THEN ep.value.int_value END) AS score
  FROM `firebase-public-project.analytics_153293282.events_20180915` AS t,
  UNNEST(t.event_params) AS ep
  WHERE t.event_name = 'level_complete_quickplay'
  GROUP BY t.event_timestamp
)
WHERE board IS NOT NULL AND score IS NOT NULL
GROUP BY Board_Type;