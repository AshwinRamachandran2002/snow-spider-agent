WITH shots AS (
  SELECT
    game_id,
    shot_type,
    event_coord_x,
    event_coord_y,
    team_basket,
    shot_made
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE
        scheduled_date < '2018-03-15'                 -- before 15‑Mar‑2018
    AND shot_type       IS NOT NULL                   -- keep only labelled shots
    AND event_coord_x   IS NOT NULL
    AND event_coord_y   IS NOT NULL
    -- be sure the shot is taken on the basket the team is attacking
    AND ( (team_basket = 'left'  AND event_coord_x <  564)
       OR (team_basket = 'right' AND event_coord_x >= 564) )
),

/* adjust coordinates so that every shot is expressed
   relative to the basket being attacked (0,0 in the
   lower‑left corner of the half court) */
shots_adj AS (
  SELECT
    game_id,
    shot_type,
    CASE WHEN event_coord_x < 564 THEN event_coord_x
         ELSE 1128 - event_coord_x END               AS adj_x,
    CASE WHEN event_coord_x < 564 THEN 600 - event_coord_y
         ELSE event_coord_y       END               AS adj_y,
    shot_made
  FROM shots
),

/* shots per game – needed to later average attempts/makes */
per_game AS (
  SELECT
    game_id,
    shot_type,
    COUNT(*)                                           AS attempts,
    SUM(CASE WHEN shot_made THEN 1 ELSE 0 END)        AS made
  FROM shots_adj
  GROUP BY game_id, shot_type
),

/* average coordinates for every individual shot */
avg_coords AS (
  SELECT
    shot_type,
    AVG(adj_x) AS avg_x_coord,
    AVG(adj_y) AS avg_y_coord
  FROM shots_adj
  GROUP BY shot_type
),

/* average attempts / made shots per game */
avg_counts AS (
  SELECT
    shot_type,
    AVG(attempts) AS avg_attempts,
    AVG(made)     AS avg_made
  FROM per_game
  GROUP BY shot_type
)

SELECT
  c.shot_type,
  ROUND(c.avg_x_coord,4)  AS avg_x_coord,
  ROUND(c.avg_y_coord,4)  AS avg_y_coord,
  ROUND(a.avg_attempts,4) AS avg_attempts,
  ROUND(a.avg_made,4)     AS avg_made
FROM avg_coords c
JOIN avg_counts a USING (shot_type)
ORDER BY shot_type;