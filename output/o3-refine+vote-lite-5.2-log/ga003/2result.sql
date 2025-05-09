/* Average score (param "value") by board type (param "board")
   for quick‑play level completions that happened on 15‑Sep‑2018. */

SELECT
  board_type                                    AS board,
  ROUND(AVG(score), 4)                          AS avg_score
FROM (
  SELECT
    -- board letter / code
    ( SELECT ep.value.string_value
      FROM   UNNEST(event_params) AS ep
      WHERE  ep.key = 'board'
      LIMIT  1 )                     AS board_type,

    -- numeric score attached to the completion
    ( SELECT
          COALESCE(ep.value.int_value,
                   ep.value.double_value,
                   ep.value.float_value)
      FROM   UNNEST(event_params) AS ep
      WHERE  ep.key = 'value'
      LIMIT  1 )                   AS score
  FROM `firebase-public-project.analytics_153293282.events_20180915`
  WHERE event_name = 'level_complete_quickplay'
)
WHERE board_type IS NOT NULL
  AND score IS NOT NULL
GROUP BY board_type
ORDER BY avg_score DESC, board_type;