SELECT
  shot_type,
  /* standardised half-court coordinates */
  AVG(CASE
        WHEN event_coord_x < 564 THEN event_coord_x
        ELSE 1128 - event_coord_x
      END) AS avg_x,
  AVG(CASE
        WHEN event_coord_x < 564 THEN 600 - event_coord_y
        ELSE event_coord_y
      END) AS avg_y,
  /* volume & efficiency */
  COUNT(*) AS attempts,
  SUM(CASE WHEN shot_made THEN 1 ELSE 0 END) AS made
FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
WHERE scheduled_date < '2018-03-15'                     -- before 15-Mar-2018
  AND shot_type IS NOT NULL                             -- keep only real shots
  AND event_coord_x IS NOT NULL
  AND event_coord_y IS NOT NULL
  /* keep shots taken at the correct basket */
  AND (
        (team_basket = 'left'  AND event_coord_x <  564) OR
        (team_basket = 'right' AND event_coord_x >= 564)
      )
GROUP BY shot_type
ORDER BY shot_type;