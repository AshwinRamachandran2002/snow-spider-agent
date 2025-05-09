SELECT
  board_type,
  AVG(score) AS avg_score
FROM (
  SELECT
    (SELECT p.value.string_value
       FROM UNNEST(event_params) AS p
       WHERE p.key = 'board') AS board_type,
    (SELECT p.value.int_value
       FROM UNNEST(event_params) AS p
       WHERE p.key = 'value') AS score
  FROM `firebase-public-project.analytics_153293282.events_20180915`
  WHERE event_name = 'level_complete_quickplay'
)
WHERE board_type IS NOT NULL
  AND score      IS NOT NULL
GROUP BY board_type
ORDER BY avg_score DESC;