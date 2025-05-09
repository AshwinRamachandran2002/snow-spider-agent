-- Average “value” score per board for quick-play completions on 15-Sep-2018
SELECT
  board,
  ROUND(AVG(score), 4) AS average_score
FROM (
  SELECT
    (SELECT p.value.string_value FROM UNNEST(event_params) AS p WHERE p.key = 'board') AS board,
    (SELECT p.value.int_value   FROM UNNEST(event_params) AS p WHERE p.key = 'value') AS score
  FROM `firebase-public-project.analytics_153293282.events_20180915`
  WHERE event_name = 'level_complete_quickplay'
)
GROUP BY board
ORDER BY average_score DESC;