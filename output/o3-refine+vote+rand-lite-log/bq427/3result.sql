WITH filtered_shots AS (
  SELECT
    shot_type,
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
    shot_made,
    game_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE
        scheduled_date < '2018-03-15'          -- before 15‑Mar‑2018
    AND shot_type IS NOT NULL                 -- exclude unknown shot types
    AND event_coord_x IS NOT NULL
    AND event_coord_y IS NOT NULL
    AND team_basket IS NOT NULL               -- need basket orientation
    -- keep only shots taken on the correct half of the court
    AND (
         (team_basket = 'left'  AND event_coord_x <  564) OR
         (team_basket = 'right' AND event_coord_x >= 564)
        )
)

SELECT
  shot_type,
  ROUND(AVG(adj_x),4)                                             AS avg_x_coord,
  ROUND(AVG(adj_y),4)                                             AS avg_y_coord,
  ROUND(COUNT(*) / COUNT(DISTINCT game_id),4)                     AS avg_attempts_per_game,
  ROUND(SUM(IF(shot_made,1,0)) / COUNT(DISTINCT game_id),4)       AS avg_made_per_game
FROM filtered_shots
GROUP BY shot_type
ORDER BY shot_type;