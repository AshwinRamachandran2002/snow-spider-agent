WITH filtered AS (
  SELECT
    game_id,
    shot_type,
    shot_made,
    IF(event_coord_x < 564, event_coord_x, 1128 - event_coord_x) AS adj_x,
    IF(event_coord_x < 564, 600 - event_coord_y, event_coord_y)  AS adj_y
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE
        scheduled_date < '2018-03-15'
    AND shot_type IS NOT NULL
    AND event_coord_x IS NOT NULL
    AND event_coord_y IS NOT NULL
    AND (
          (team_basket = 'left'  AND event_coord_x < 564) OR
          (team_basket = 'right' AND event_coord_x >= 564)
        )
),
coord_avgs AS (
  SELECT
    shot_type,
    AVG(adj_x) AS avg_x_coordinate,
    AVG(adj_y) AS avg_y_coordinate
  FROM filtered
  GROUP BY shot_type
),
attempt_avgs AS (
  SELECT
    shot_type,
    AVG(attempts) AS avg_shot_attempts,
    AVG(makes)    AS avg_successful_shots
  FROM (
    SELECT
      game_id,
      shot_type,
      COUNT(*)                                   AS attempts,
      SUM(CASE WHEN shot_made THEN 1 ELSE 0 END) AS makes
    FROM filtered
    GROUP BY game_id, shot_type
  )
  GROUP BY shot_type
)
SELECT
  c.shot_type,
  ROUND(c.avg_x_coordinate, 4)     AS avg_x_coordinate,
  ROUND(c.avg_y_coordinate, 4)     AS avg_y_coordinate,
  ROUND(a.avg_shot_attempts, 4)    AS avg_shot_attempts,
  ROUND(a.avg_successful_shots, 4) AS avg_successful_shots
FROM coord_avgs c
JOIN attempt_avgs a
USING (shot_type)
ORDER BY shot_type;