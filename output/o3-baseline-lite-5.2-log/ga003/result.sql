WITH quickplay_completions AS (
  SELECT
    -- board type (e.g. 'S', 'L', etc.)
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) AS ep
     WHERE ep.key = 'board')                    AS board_type,

    -- score of the completion (stored under the key 'value')
    (SELECT CASE
              WHEN vp.value.int_value   IS NOT NULL THEN CAST(vp.value.int_value   AS FLOAT64)
              WHEN vp.value.double_value IS NOT NULL THEN vp.value.double_value
              WHEN vp.value.float_value  IS NOT NULL THEN CAST(vp.value.float_value AS FLOAT64)
            END
     FROM UNNEST(event_params) AS vp
     WHERE vp.key = 'value')                   AS score
  FROM `firebase-public-project.analytics_153293282.events_20180915`
  WHERE event_name = 'level_complete_quickplay'
)

SELECT
  board_type,
  AVG(score) AS average_score
FROM quickplay_completions
WHERE board_type IS NOT NULL
GROUP BY board_type
ORDER BY average_score DESC;