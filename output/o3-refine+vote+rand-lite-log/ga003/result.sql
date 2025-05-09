/* Average quick‑play score (event param "value") per board type
   for September 15 2018                                          */
SELECT
  board_type                                    AS board,
  AVG(score)                                    AS average_score
FROM (
  SELECT
    /* board type (e.g. 'S', 'L', …)                               */
    ( SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'board'
      LIMIT 1 )                         AS board_type,

    /* score recorded in param "value"                              */
    ( SELECT CASE
               WHEN ep.value.int_value   IS NOT NULL THEN CAST(ep.value.int_value AS FLOAT64)
               WHEN ep.value.double_value IS NOT NULL THEN ep.value.double_value
               WHEN ep.value.float_value  IS NOT NULL THEN CAST(ep.value.float_value  AS FLOAT64)
             END
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'value'
      LIMIT 1 )                         AS score
  FROM `firebase-public-project.analytics_153293282.events_20180915`
  WHERE event_name = 'level_complete_quickplay'
)
WHERE board_type IS NOT NULL
  AND score      IS NOT NULL
GROUP BY board_type
ORDER BY average_score DESC;