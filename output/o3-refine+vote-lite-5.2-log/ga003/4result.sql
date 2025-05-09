WITH quickplay AS (
  SELECT
    MAX(CASE WHEN ep.key = 'board'  THEN ep.value.string_value END) AS board,
    MAX(CASE WHEN ep.key = 'value'  THEN ep.value.int_value END)   AS score
  FROM
    `firebase-public-project.analytics_153293282.events_20180915`
  CROSS JOIN
    UNNEST(event_params) AS ep
  WHERE
    event_name = 'level_complete_quickplay'   -- quick‑play completions
    AND event_date = '20180915'               -- 15‑Sep‑2018
  GROUP BY
    event_timestamp,
    user_pseudo_id                            -- one row per event
)

SELECT
  board,
  ROUND(AVG(score), 4) AS average_score
FROM
  quickplay
WHERE
  board IS NOT NULL
  AND score IS NOT NULL
GROUP BY
  board
ORDER BY
  average_score DESC;