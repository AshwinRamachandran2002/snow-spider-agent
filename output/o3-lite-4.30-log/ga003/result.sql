SELECT
  board.value.string_value AS board_type,
  ROUND(
    AVG(
      CAST(
        COALESCE(score.value.int_value,
                 score.value.float_value,
                 score.value.double_value) AS FLOAT64)
    ), 4) AS average_score
FROM `firebase-public-project.analytics_153293282.events_20180915`,
     UNNEST(event_params) AS board
JOIN UNNEST(event_params) AS score
WHERE event_date = '20180915'
  AND event_name = 'level_complete_quickplay'
  AND board.key = 'board'
  AND score.key = 'value'
GROUP BY board_type
ORDER BY average_score DESC;