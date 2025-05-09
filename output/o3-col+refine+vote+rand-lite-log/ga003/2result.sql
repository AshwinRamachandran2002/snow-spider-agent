SELECT
  ep_board.value.string_value              AS board_type,
  ROUND(AVG(ep_score.value.int_value), 4)  AS avg_score
FROM `firebase-public-project.analytics_153293282.events_20180915`,
     UNNEST(event_params) AS ep_board
JOIN UNNEST(event_params) AS ep_score
  ON TRUE
WHERE event_name = 'level_complete_quickplay'
  AND event_date = '20180915'
  AND ep_board.key = 'board'
  AND ep_score.key = 'value'
GROUP BY board_type
ORDER BY avg_score DESC;