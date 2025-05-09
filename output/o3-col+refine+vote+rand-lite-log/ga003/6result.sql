-- Average score per board type for quick-play completions on 15-Sep-2018
SELECT
  board_type,
  AVG(score) AS avg_score
FROM (
  SELECT
    MAX(CASE WHEN ep.key = 'board' THEN ep.value.string_value END) AS board_type,
    MAX(CASE WHEN ep.key = 'value' THEN ep.value.int_value END)   AS score
  FROM `firebase-public-project.analytics_153293282.events_20180915`,
       UNNEST(event_params) AS ep
  WHERE event_name = 'level_complete_quickplay'
  GROUP BY event_timestamp          -- one row per completion event
)
GROUP BY board_type
ORDER BY avg_score DESC;