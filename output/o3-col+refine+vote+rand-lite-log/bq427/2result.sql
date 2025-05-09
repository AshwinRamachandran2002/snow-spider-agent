WITH filtered AS (
  SELECT
    `game_id`,
    `shot_type`,
    CASE
      WHEN `event_coord_x` < 564 THEN `event_coord_x`
      ELSE 1128 - `event_coord_x`
    END AS adj_x,
    CASE
      WHEN `event_coord_x` < 564 THEN 600 - `event_coord_y`
      ELSE `event_coord_y`
    END AS adj_y,
    `shot_made`
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE `shot_type` IS NOT NULL
    AND `event_coord_x` IS NOT NULL
    AND `event_coord_y` IS NOT NULL
    AND `scheduled_date` < '2018-03-15'
    AND (
          (`team_basket` = 'left'  AND `event_coord_x` <  564) OR
          (`team_basket` = 'right' AND `event_coord_x` >= 564)
        )
),
per_game AS (
  SELECT
    `game_id`,
    `shot_type`,
    COUNT(*) AS attempts,
    SUM(CASE WHEN `shot_made` THEN 1 ELSE 0 END) AS makes,
    AVG(adj_x) AS avg_x_game,
    AVG(adj_y) AS avg_y_game
  FROM filtered
  GROUP BY `game_id`, `shot_type`
)
SELECT
  `shot_type`,
  AVG(avg_x_game)      AS avg_x_coordinate,
  AVG(avg_y_game)      AS avg_y_coordinate,
  AVG(attempts)        AS avg_attempts_per_game,
  AVG(makes)           AS avg_makes_per_game
FROM per_game
GROUP BY `shot_type`
ORDER BY `shot_type`;