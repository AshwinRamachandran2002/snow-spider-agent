WITH shots AS (
  SELECT
    game_id,
    shot_type,
    
    -- map every attempt to the “left” basket reference frame
    CASE
      WHEN event_coord_x < 564 THEN event_coord_x
      ELSE 1128 - event_coord_x
    END AS adj_x,
    CASE
      WHEN event_coord_x < 564 THEN 600 - event_coord_y
      ELSE event_coord_y
    END AS adj_y,
    
    IF(shot_made, 1, 0) AS is_made
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE
        -- only games before 15‑Mar‑2018
        DATE(scheduled_date) < '2018-03-15'
    AND shot_type IS NOT NULL                     -- keep rows that are labelled as shots
    AND event_coord_x IS NOT NULL
    AND event_coord_y IS NOT NULL
),
per_game AS (
  SELECT
    game_id,
    shot_type,
    COUNT(*)           AS attempts_in_game,
    SUM(is_made)       AS makes_in_game,
    AVG(adj_x)         AS avg_x_in_game,
    AVG(adj_y)         AS avg_y_in_game
  FROM shots
  GROUP BY game_id, shot_type
)
SELECT
  shot_type,
  AVG(avg_x_in_game)      AS avg_x_coordinate,
  AVG(avg_y_in_game)      AS avg_y_coordinate,
  AVG(attempts_in_game)   AS avg_shot_attempts,
  AVG(makes_in_game)      AS avg_successful_shots
FROM per_game
GROUP BY shot_type
ORDER BY shot_type;