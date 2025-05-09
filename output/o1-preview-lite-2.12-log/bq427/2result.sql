SELECT
  `shot_type`,
  ROUND(AVG(
    CASE
      WHEN `team_basket` = 'left' THEN `event_coord_x`
      WHEN `team_basket` = 'right' THEN 1128 - `event_coord_x`
    END
  ), 4) AS avg_adjusted_x_coordinate,
  ROUND(AVG(
    CASE
      WHEN `team_basket` = 'left' THEN 600 - `event_coord_y`
      WHEN `team_basket` = 'right' THEN `event_coord_y`
    END
  ), 4) AS avg_adjusted_y_coordinate,
  COUNT(*) AS avg_shot_attempts,
  SUM(
    CASE
      WHEN `event_type` IN ('twopointmade', 'threepointmade') THEN 1
      ELSE 0
    END
  ) AS avg_successful_shots
FROM
  `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
WHERE
  `scheduled_date` < '2018-03-15'
  AND `event_type` IN ('twopointmade', 'twopointmiss', 'threepointmade', 'threepointmiss')
  AND `shot_type` IS NOT NULL
  AND `event_coord_x` IS NOT NULL
  AND `event_coord_y` IS NOT NULL
  AND `team_basket` IN ('left', 'right')
  AND (
    (`team_basket` = 'left' AND `event_coord_x` < 564)
    OR (`team_basket` = 'right' AND `event_coord_x` >= 564)
  )
GROUP BY `shot_type`
ORDER BY `shot_type`;