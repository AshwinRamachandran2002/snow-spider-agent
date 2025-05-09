WITH shots AS (
  SELECT
    game_id,
    shot_type,
    shot_made,
    scheduled_date,
    team_basket,
    -- keep raw coords only if they are on the team's attacking half
    event_coord_x,
    event_coord_y
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE
        -- only events that are actually shots and have coordinates
        shot_type IS NOT NULL
    AND event_coord_x IS NOT NULL
    AND event_coord_y IS NOT NULL
    -- only games before 15‑Mar‑2018
    AND scheduled_date < '2018-03-15'
    -- insure the shot is taken toward the team’s offensive basket
    AND (
          (team_basket = 'left'  AND event_coord_x < 564) OR
          (team_basket = 'right' AND event_coord_x >= 564)
        )
),
-- adjust coordinates so every shot is expressed relative to the shooting basket
adj_shots AS (
  SELECT
    game_id,
    shot_type,
    shot_made,
    -- coordinate adjustments per the rules in the prompt
    CASE
      WHEN event_coord_x < 564 THEN event_coord_x
      ELSE 1128 - event_coord_x
    END AS adj_x,
    CASE
      WHEN event_coord_x < 564 THEN 600 - event_coord_y
      ELSE event_coord_y
    END AS adj_y
  FROM shots
),
-- count attempts and made shots per game & shot type
game_level AS (
  SELECT
    game_id,
    shot_type,
    AVG(adj_x)                   AS game_avg_x,
    AVG(adj_y)                   AS game_avg_y,
    COUNT(*)                     AS attempts_in_game,
    SUM(CASE WHEN shot_made THEN 1 ELSE 0 END) AS made_in_game
  FROM adj_shots
  GROUP BY game_id, shot_type
)
-- final averages across all games
SELECT
  shot_type,
  ROUND(AVG(game_avg_x), 4)        AS avg_x,
  ROUND(AVG(game_avg_y), 4)        AS avg_y,
  ROUND(AVG(attempts_in_game), 4)  AS avg_attempts,
  ROUND(AVG(made_in_game), 4)      AS avg_made
FROM game_level
GROUP BY shot_type
ORDER BY shot_type;