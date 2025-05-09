/*  Average (adjusted) shot location and outcomes by shot_type
    – only shots with non-NULL type & coordinates
    – keep shots taken on correct attacking half
    – restrict to games played before 15-Mar-2018            */

WITH cleaned AS (
  SELECT
    shot_type,
    game_id,
    -- standardise all shots toward the same basket
    CASE
      WHEN event_coord_x < 564 THEN event_coord_x
      ELSE 1128 - event_coord_x
    END                                          AS adj_x,
    CASE
      WHEN event_coord_x < 564 THEN 600 - event_coord_y
      ELSE event_coord_y
    END                                          AS adj_y,
    shot_made
  FROM   `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE
      shot_type       IS NOT NULL
  AND event_coord_x   IS NOT NULL
  AND event_coord_y   IS NOT NULL
  AND DATE(scheduled_date) < '2018-03-15'         -- before 15-Mar-2018
  AND (                                             -- correct half-court
        (team_basket = 'left'  AND event_coord_x <  564) OR
        (team_basket = 'right' AND event_coord_x >= 564)
      )
),

per_game AS (
  SELECT
    shot_type,
    game_id,
    COUNT(*)                           AS attempts,
    SUM(CASE WHEN shot_made THEN 1 END) AS made,
    AVG(adj_x)                         AS avg_x_in_game,
    AVG(adj_y)                         AS avg_y_in_game
  FROM cleaned
  GROUP BY shot_type, game_id
)

SELECT
  shot_type,
  ROUND(AVG(avg_x_in_game),4) AS avg_adj_x,
  ROUND(AVG(avg_y_in_game),4) AS avg_adj_y,
  ROUND(AVG(attempts),4)      AS avg_attempts,
  ROUND(AVG(made),4)          AS avg_made
FROM per_game
GROUP BY shot_type
ORDER BY shot_type;