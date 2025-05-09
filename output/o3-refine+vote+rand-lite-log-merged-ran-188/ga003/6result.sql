-- Average quick‑play completion scores per board on 15‑Sep‑2018
SELECT
  board_type,
  AVG(score) AS avg_score
FROM (
  SELECT
    -- board identifier (e.g., S, M, L …)
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'board')               AS board_type,

    -- completion score for that level
    (SELECT COALESCE(ep.value.int_value,
                     CAST(ep.value.double_value AS INT64),
                     CAST(ep.value.float_value  AS INT64))
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'value')               AS score
  FROM `firebase-public-project.analytics_153293282.events_20180915`
  WHERE event_name = 'level_complete_quickplay'
)
WHERE board_type IS NOT NULL
  AND score IS NOT NULL
GROUP BY board_type
ORDER BY avg_score DESC;