WITH quickplay AS (
  SELECT
    board_param.value.string_value AS board_type,
    value_param.value.int_value    AS score
  FROM `firebase-public-project.analytics_153293282.events_20180915`,
  UNNEST(event_params) AS board_param
  JOIN UNNEST(event_params) AS value_param
  WHERE event_name = 'level_complete_quickplay'
    AND board_param.key = 'board'
    AND value_param.key = 'value'
    AND value_param.value.int_value IS NOT NULL
)

SELECT
  board_type,
  COUNT(*)                 AS completions,
  ROUND(AVG(score), 4)     AS average_score
FROM quickplay
GROUP BY board_type
ORDER BY average_score DESC;