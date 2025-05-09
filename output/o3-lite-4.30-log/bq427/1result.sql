WITH valid_shots AS (
  SELECT
    game_id,
    shot_type,
    /* flip court so every shot is viewed from the same basket */
    IF(event_coord_x < 564, event_coord_x, 1128 - event_coord_x) AS adj_x,
    IF(event_coord_x < 564, 600 - event_coord_y, event_coord_y)  AS adj_y,
    shot_made
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE scheduled_date < '2018-03-15'
    AND shot_type IS NOT NULL
    AND event_coord_x IS NOT NULL
    AND event_coord_y IS NOT NULL
    /* keep only shots taken on the offensive half‑court */
    AND (
          (team_basket = 'left'  AND event_coord_x < 564) OR
          (team_basket = 'right' AND event_coord_x >= 564)
        )
),
per_game AS (
  SELECT
    game_id,
    shot_type,
    COUNT(*)                                    AS attempts,
    SUM(IF(shot_made, 1, 0))                    AS made,
    AVG(adj_x)                                  AS avg_x_game,
    AVG(adj_y)                                  AS avg_y_game
  FROM valid_shots
  GROUP BY game_id, shot_type
)
SELECT
  shot_type,
  ROUND(AVG(avg_x_game), 4)  AS avg_x_coordinate,
  ROUND(AVG(avg_y_game), 4)  AS avg_y_coordinate,
  ROUND(AVG(attempts), 4)    AS avg_shot_attempts,
  ROUND(AVG(made), 4)        AS avg_successful_shots
FROM per_game
GROUP BY shot_type
ORDER BY shot_type;