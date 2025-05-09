-- Average location (adjusted), average attempts, and average made shots
-- per shot_type for plays before 15 Mar 2018.
WITH shots AS (
  SELECT
    game_id,
    shot_type,
    shot_made,
    event_coord_x,
    event_coord_y,
    team_basket
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE
        scheduled_date < '2018-03-15'               -- before 15‑Mar‑2018
    AND shot_type IS NOT NULL                       -- keep only labelled shots
    AND event_coord_x IS NOT NULL
    AND event_coord_y IS NOT NULL
    -- keep only shots taken at the basket the team is attacking
    AND (
          (team_basket = 'left'  AND event_coord_x <  564) OR
          (team_basket = 'right' AND event_coord_x >= 564)
        )
),
shots_adj AS (
  SELECT
    game_id,
    shot_type,
    shot_made,
    -- adjust X‑, Y‑coordinates so every shot is shown
    -- as if the offense is attacking the basket on the LEFT
    CASE
      WHEN event_coord_x < 564
           THEN event_coord_x
      ELSE 1128 - event_coord_x
    END AS adj_x,
    CASE
      WHEN event_coord_x < 564
           THEN 600 - event_coord_y
      ELSE event_coord_y
    END AS adj_y
  FROM shots
),
per_game AS (   -- counts per game, later averaged over games
  SELECT
    shot_type,
    game_id,
    COUNT(*)                                             AS attempts,
    SUM(CASE WHEN shot_made THEN 1 ELSE 0 END)           AS made
  FROM shots_adj
  GROUP BY shot_type, game_id
),
coord_avg AS (  -- overall mean location per shot_type
  SELECT
    shot_type,
    AVG(adj_x) AS avg_x,
    AVG(adj_y) AS avg_y
  FROM shots_adj
  GROUP BY shot_type
)
SELECT
  c.shot_type,
  c.avg_x,
  c.avg_y,
  g.avg_attempts,
  g.avg_made
FROM coord_avg c
JOIN (
  SELECT
    shot_type,
    AVG(attempts) AS avg_attempts,
    AVG(made)     AS avg_made
  FROM per_game
  GROUP BY shot_type
) g
ON c.shot_type = g.shot_type
ORDER BY c.shot_type;