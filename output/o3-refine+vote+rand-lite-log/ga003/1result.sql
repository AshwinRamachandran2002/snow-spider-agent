SELECT
  board,
  ROUND(AVG(score), 4) AS avg_score
FROM (
  SELECT
    -- Board type used in the quick‑play level
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'board'
      LIMIT 1) AS board,

    -- Score obtained in that level
    (SELECT COALESCE(ep.value.double_value,
                     ep.value.float_value,
                     ep.value.int_value)
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'value'
      LIMIT 1) AS score
  FROM `firebase-public-project.analytics_153293282.events_20180915`
  WHERE event_name = 'level_complete_quickplay'
    AND event_date  = '20180915'
)
WHERE board IS NOT NULL
  AND score IS NOT NULL
GROUP BY board
ORDER BY avg_score DESC;