WITH valid_shots AS (
  SELECT
    shot_type,
    game_id,
    -- adjust X coordinate
    CASE
      WHEN event_coord_x < 564 THEN event_coord_x
      ELSE 1128 - event_coord_x
    END AS adj_x,
    -- adjust Y coordinate
    CASE
      WHEN event_coord_x < 564 THEN 600 - event_coord_y
      ELSE event_coord_y
    END AS adj_y,
    shot_made
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE shot_type IS NOT NULL
    AND event_coord_x IS NOT NULL
    AND event_coord_y IS NOT NULL
    AND DATE(scheduled_date) < '2018-03-15'
    -- keep only shots taken at the correct half-court basket
    AND (
          (team_basket = 'left'  AND event_coord_x < 564) OR
          (team_basket = 'right' AND event_coord_x > 564)
        )
),
per_game AS (
  SELECT
    shot_type,
    game_id,
    COUNT(*)                   AS attempts,
    COUNTIF(shot_made)         AS made,
    AVG(adj_x)                 AS avg_x_game,
    AVG(adj_y)                 AS avg_y_game
  FROM valid_shots
  GROUP BY shot_type, game_id
)
SELECT
  shot_type,
  AVG(avg_x_game) AS average_adjusted_x_coordinate,
  AVG(avg_y_game) AS average_adjusted_y_coordinate,
  AVG(attempts)   AS average_attempts_per_game,
  AVG(made)       AS average_made_per_game
FROM per_game
GROUP BY shot_type
ORDER BY shot_type;