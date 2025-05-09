WITH shots AS (
  SELECT
    shot_type,
    game_id,
    shot_made,
    -- adjust X
    CASE
      WHEN event_coord_x < 564 THEN event_coord_x
      ELSE 1128 - event_coord_x
    END                                                   AS x_adj,
    -- adjust Y
    CASE
      WHEN event_coord_x < 564 THEN 600 - event_coord_y
      ELSE event_coord_y
    END                                                   AS y_adj
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE scheduled_date < '2018-03-15'                            -- before Mar‑15‑2018
    AND shot_type IS NOT NULL                                    -- valid shot type
    AND event_coord_x IS NOT NULL
    AND event_coord_y IS NOT NULL                                -- valid coords
    AND (
          (team_basket = 'left'  AND event_coord_x <  564) OR    -- correct side
          (team_basket = 'right' AND event_coord_x >= 564)
        )
    AND shot_made IS NOT NULL                                    -- keep only shot events
),

-- average (x,y) location for each shot‑type
coord_avg AS (
  SELECT
    shot_type,
    AVG(x_adj) AS avg_x_coord,
    AVG(y_adj) AS avg_y_coord
  FROM shots
  GROUP BY shot_type
),

-- attempts & made per game
game_counts AS (
  SELECT
    shot_type,
    game_id,
    COUNT(*)                                   AS attempts,
    SUM(CASE WHEN shot_made THEN 1 ELSE 0 END) AS made
  FROM shots
  GROUP BY shot_type, game_id
),

-- average attempts & made across games
game_avg AS (
  SELECT
    shot_type,
    AVG(attempts) AS avg_attempts,
    AVG(made)     AS avg_made
  FROM game_counts
  GROUP BY shot_type
)

SELECT
  c.shot_type,
  c.avg_x_coord,
  c.avg_y_coord,
  g.avg_attempts,
  g.avg_made
FROM coord_avg c
JOIN game_avg g USING (shot_type)
ORDER BY c.shot_type;