WITH quickplay_completions AS (
  SELECT
    -- board type played (e.g., "S", "M", ... )
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'board')            AS board_type,
    -- score obtained for that completion
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'value')            AS score
  FROM `firebase-public-project.analytics_153293282.events_20180915`
  WHERE event_name = 'level_complete_quickplay'
)
SELECT
  board_type,
  AVG(score) AS avg_score
FROM quickplay_completions
WHERE board_type IS NOT NULL
GROUP BY board_type
ORDER BY avg_score DESC;