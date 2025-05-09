WITH shots AS (
  SELECT
    game_id,
    shot_type,
    team_basket,
    -- adjusted coordinates (put all shots on the same attacking‐basket frame)
    CASE
      WHEN event_coord_x < 564 THEN event_coord_x
      ELSE 1128 - event_coord_x
    END AS adj_x,
    CASE
      WHEN event_coord_x < 564 THEN 600 - event_coord_y
      ELSE event_coord_y
    END AS adj_y,
    -- shot outcome
    CASE
      WHEN shot_made THEN 1
      ELSE 0
    END AS made
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE
        scheduled_date < '2018-03-15'          -- only games before 15‑Mar‑2018
    AND shot_type IS NOT NULL                  -- ignore unknown shot types
    AND event_coord_x IS NOT NULL              -- need valid coordinates
    AND event_coord_y IS NOT NULL
    -- keep shots taken in the half‑court that the team is attacking
    AND (
          (team_basket = 'left'  AND event_coord_x <  564) OR
          (team_basket = 'right' AND event_coord_x >= 564)
        )
),
-- count attempts / makes in every game for each shot type
per_game AS (
  SELECT
    game_id,
    shot_type,
    COUNT(*)                    AS attempts,
    SUM(made)                   AS made,
    AVG(adj_x)                  AS avg_x_game,
    AVG(adj_y)                  AS avg_y_game
  FROM shots
  GROUP BY game_id, shot_type
)
SELECT
  shot_type,
  AVG(avg_x_game) AS avg_adj_x,     -- mean adjusted‑X across games
  AVG(avg_y_game) AS avg_adj_y,     -- mean adjusted‑Y across games
  AVG(attempts)   AS avg_attempts,  -- mean attempts per game
  AVG(made)       AS avg_made       -- mean made shots per game
FROM per_game
GROUP BY shot_type
ORDER BY shot_type;