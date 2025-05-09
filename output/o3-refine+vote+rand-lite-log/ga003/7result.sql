/* Average score per board type for Quick‑Play completions on 15‑Sept‑2018 */
WITH quickplay AS (
  SELECT
    /* board type (e.g., 'S', 'M', etc.) */
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'board')              AS board_type,

    /* score recorded in the "value" event parameter                */
    /* prefer int_value, fall back to double_value if necessary     */
    COALESCE(
      (SELECT ep.value.int_value
         FROM UNNEST(event_params) AS ep
        WHERE ep.key = 'value'),
      CAST( (SELECT ep.value.double_value
               FROM UNNEST(event_params) AS ep
              WHERE ep.key = 'value') AS INT64 )
    )                                      AS score
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX = '20180915'                 -- 15‑Sep‑2018
    AND event_name = 'level_complete_quickplay'    -- quick‑play completions
)

SELECT
  board_type,
  AVG(score) AS average_score
FROM quickplay
WHERE board_type IS NOT NULL
GROUP BY board_type
ORDER BY average_score DESC;