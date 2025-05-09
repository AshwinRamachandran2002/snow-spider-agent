-- For each shot type, compute:
--   1) average adjusted X & Y coordinates (always from the shooter’s perspective)
--   2) average shot attempts per game
--   3) average made-shots per game
--   * Only use shots taken before 15-Mar-2018
--   * Exclude rows with NULL shot information / coordinates
--   * Keep shots that are on the correct half-court for the team’s attacking basket
WITH shots AS (
  SELECT
    game_id,
    shot_type,
    shot_made,
    -- adjust coordinates so every shot is measured toward the left basket
    CASE
      WHEN event_coord_x < 564 THEN event_coord_x
      ELSE 1128 - event_coord_x
    END AS adj_x,
    CASE
      WHEN event_coord_x < 564 THEN 600 - event_coord_y
      ELSE event_coord_y
    END AS adj_y
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE shot_type IS NOT NULL
    AND event_coord_x IS NOT NULL
    AND event_coord_y IS NOT NULL
    AND scheduled_date < '2018-03-15'
    -- keep only shots taken on the proper side of the floor
    AND (
          (team_basket = 'left'  AND event_coord_x < 564) OR
          (team_basket = 'right' AND event_coord_x >= 564)
        )
),
per_game AS (                      -- attempts & makes per game / shot type
  SELECT
    game_id,
    shot_type,
    COUNT(*)                                         AS attempts,
    SUM(CASE WHEN shot_made THEN 1 ELSE 0 END)      AS makes
  FROM shots
  GROUP BY game_id, shot_type
),
avg_coords AS (                     -- average adjusted coordinates
  SELECT
    shot_type,
    AVG(adj_x) AS avg_adj_x,
    AVG(adj_y) AS avg_adj_y
  FROM shots
  GROUP BY shot_type
),
avg_game AS (                       -- average attempts & makes per game
  SELECT
    shot_type,
    AVG(attempts) AS avg_attempts_per_game,
    AVG(makes)    AS avg_makes_per_game
  FROM per_game
  GROUP BY shot_type
)
SELECT
  c.shot_type,
  ROUND(c.avg_adj_x, 4)            AS avg_adj_x,
  ROUND(c.avg_adj_y, 4)            AS avg_adj_y,
  ROUND(g.avg_attempts_per_game,4) AS avg_attempts_per_game,
  ROUND(g.avg_makes_per_game,4)    AS avg_makes_per_game
FROM avg_coords c
JOIN avg_game  g USING (shot_type)
ORDER BY shot_type;