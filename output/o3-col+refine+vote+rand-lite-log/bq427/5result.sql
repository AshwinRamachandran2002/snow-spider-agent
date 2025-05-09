WITH base AS (
  SELECT
    game_id,
    shot_type,
    -- Adjust X-coordinate (mirror right-hand half)
    CASE
      WHEN event_coord_x < 564 THEN event_coord_x
      ELSE 1128 - event_coord_x
    END AS adj_x,
    -- Adjust Y-coordinate (flip only for left-side shots)
    CASE
      WHEN event_coord_x < 564 THEN 600 - event_coord_y
      ELSE event_coord_y
    END AS adj_y,
    shot_made
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE shot_type IS NOT NULL
    AND event_coord_x IS NOT NULL
    AND event_coord_y IS NOT NULL
    AND scheduled_date < '2018-03-15'
    -- Keep only shots taken on the correct half of the floor
    AND (
          (team_basket = 'left'  AND event_coord_x < 564) OR
          (team_basket = 'right' AND event_coord_x > 564)
        )
),
per_game AS (
  SELECT
    game_id,
    shot_type,
    AVG(adj_x) AS game_mean_x,
    AVG(adj_y) AS game_mean_y,
    COUNT(*)   AS attempts,
    SUM(CASE WHEN shot_made THEN 1 ELSE 0 END) AS made
  FROM base
  GROUP BY game_id, shot_type
)
SELECT
  shot_type,
  ROUND(AVG(game_mean_x), 4) AS avg_adj_x,
  ROUND(AVG(game_mean_y), 4) AS avg_adj_y,
  ROUND(AVG(attempts),    4) AS avg_attempts,
  ROUND(AVG(made),        4) AS avg_made
FROM per_game
GROUP BY shot_type
ORDER BY shot_type;