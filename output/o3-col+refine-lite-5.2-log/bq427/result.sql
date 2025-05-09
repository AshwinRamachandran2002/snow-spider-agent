-- Average adjusted shot location, attempts and makes per shot type
WITH filtered_shots AS (
  SELECT
    game_id,
    shot_type,
    shot_made,
    -- adjusted coordinates
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
    AND scheduled_date < TIMESTAMP('2018-03-15')
    AND (
          (team_basket = 'left'  AND event_coord_x <  564) OR
          (team_basket = 'right' AND event_coord_x >= 564)
        )
),
-- overall coordinate averages (weighted by every shot)
shot_coords AS (
  SELECT
    shot_type,
    ROUND(AVG(adj_x), 4) AS avg_adj_x,
    ROUND(AVG(adj_y), 4) AS avg_adj_y
  FROM filtered_shots
  GROUP BY shot_type
),
-- per‑game attempts & makes
per_game_counts AS (
  SELECT
    game_id,
    shot_type,
    COUNT(*) AS attempts,
    SUM(CASE WHEN shot_made THEN 1 ELSE 0 END) AS made
  FROM filtered_shots
  GROUP BY game_id, shot_type
),
-- average attempts & makes across games
avg_counts AS (
  SELECT
    shot_type,
    ROUND(AVG(attempts), 4) AS avg_attempts,
    ROUND(AVG(made), 4)     AS avg_made
  FROM per_game_counts
  GROUP BY shot_type
)
SELECT
  c.shot_type,
  c.avg_adj_x,
  c.avg_adj_y,
  a.avg_attempts,
  a.avg_made
FROM shot_coords  c
JOIN avg_counts  a USING (shot_type)
ORDER BY shot_type;