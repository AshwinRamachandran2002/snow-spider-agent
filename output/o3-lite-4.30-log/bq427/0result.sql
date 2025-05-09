WITH cleaned AS (
  SELECT
    game_id,
    shot_type,
    /* convert all shots to the same half‑court reference frame */
    CASE
      WHEN event_coord_x < 564 THEN event_coord_x
      ELSE 1128 - event_coord_x
    END AS adj_x,
    CASE
      WHEN event_coord_x < 564 THEN 600 - event_coord_y
      ELSE event_coord_y
    END AS adj_y,
    IFNULL(shot_made, FALSE) AS shot_made
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE
        scheduled_date < '2018-03-15'
    AND shot_type IS NOT NULL
    AND event_coord_x IS NOT NULL
    AND event_coord_y IS NOT NULL
    /* keep only shots attempted at the basket the team was attacking */
    AND (
          (team_basket = 'left'  AND event_coord_x < 564) OR
          (team_basket = 'right' AND event_coord_x >= 564)
        )
),
per_game AS (
  /* one row per game & shot type */
  SELECT
    game_id,
    shot_type,
    COUNT(*) AS attempts,
    SUM(CASE WHEN shot_made THEN 1 ELSE 0 END) AS made
  FROM cleaned
  GROUP BY game_id, shot_type
),
coord_avgs AS (
  SELECT
    shot_type,
    AVG(adj_x) AS avg_x_coordinate,
    AVG(adj_y) AS avg_y_coordinate
  FROM cleaned
  GROUP BY shot_type
),
attempt_avgs AS (
  SELECT
    shot_type,
    AVG(attempts) AS avg_shot_attempts,
    AVG(made)     AS avg_successful_shots
  FROM per_game
  GROUP BY shot_type
)
SELECT
  c.shot_type,
  ROUND(c.avg_x_coordinate, 4)     AS avg_x_coordinate,
  ROUND(c.avg_y_coordinate, 4)     AS avg_y_coordinate,
  ROUND(a.avg_shot_attempts, 4)    AS avg_shot_attempts,
  ROUND(a.avg_successful_shots, 4) AS avg_successful_shots
FROM coord_avgs  AS c
JOIN attempt_avgs AS a USING (shot_type)
ORDER BY shot_type;