-- Average quick‑play scores by board type on 15‑Sep‑2018
WITH quickplay AS (
  SELECT
    -- board type (e.g. 'S', 'M', etc.)
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'board')  AS board,

    -- score earned for the completion
    COALESCE(
        (SELECT ep.value.int_value    FROM UNNEST(event_params) ep WHERE ep.key = 'value'),
        (SELECT ep.value.double_value FROM UNNEST(event_params) ep WHERE ep.key = 'value'),
        (SELECT ep.value.float_value  FROM UNNEST(event_params) ep WHERE ep.key = 'value')
    ) AS score
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX = '20180915'               -- 15‑Sep‑2018
    AND event_name   = 'level_complete_quickplay' -- quick‑play completions
)

SELECT
  board,
  AVG(CAST(score AS FLOAT64)) AS average_score
FROM quickplay
WHERE board IS NOT NULL
  AND score IS NOT NULL
GROUP BY board
ORDER BY average_score DESC;