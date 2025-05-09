-- Average quick-play completion score per board type on 15-Sep-2018
SELECT
  board_type,
  ROUND(AVG(score), 4) AS avg_score
FROM (
  SELECT
    (SELECT ep.value.string_value
     FROM   UNNEST(event_params) ep
     WHERE  ep.key = 'board')          AS board_type,
    (SELECT ep.value.int_value
     FROM   UNNEST(event_params) ep
     WHERE  ep.key = 'value')          AS score
  FROM   `firebase-public-project.analytics_153293282.events_20180915`
  WHERE  event_name = 'level_complete_quickplay'
)
WHERE board_type IS NOT NULL
GROUP BY board_type
ORDER BY avg_score DESC;