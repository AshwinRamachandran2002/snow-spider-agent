-- Average completion score for each board type on Sept-15, 2018 (quick-play only)
SELECT
  ep_board.value.string_value AS board_type,
  AVG(ep_value.value.int_value) AS avg_score
FROM
  `firebase-public-project.analytics_153293282.events_20180915`,
  UNNEST(`event_params`) AS ep_board,
  UNNEST(`event_params`) AS ep_value
WHERE
  `event_name` = 'level_complete_quickplay'
  AND ep_board.key = 'board'          -- board type (S, M, L, etc.)
  AND ep_value.key = 'value'          -- level completion score
GROUP BY
  board_type
ORDER BY
  avg_score DESC;