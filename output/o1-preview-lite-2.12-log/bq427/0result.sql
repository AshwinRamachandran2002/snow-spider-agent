WITH shots_data AS (
  SELECT
    shot_type,
    team_id,
    -- Adjusted X Coordinate
    CASE
      WHEN (team_basket = 'left' AND event_coord_x >= 564) OR
           (team_basket = 'right' AND event_coord_x < 564)
      THEN 1128 - event_coord_x
      ELSE event_coord_x
    END AS adjusted_x_coordinate,
    -- Adjusted Y Coordinate
    CASE
      WHEN (team_basket = 'left' AND event_coord_x < 564)
      THEN 600 - event_coord_y
      ELSE event_coord_y
    END AS adjusted_y_coordinate,
    shot_made
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE
    shot_type IS NOT NULL AND TRIM(shot_type) != ''
    AND event_coord_x IS NOT NULL
    AND event_coord_y IS NOT NULL
    AND team_basket IS NOT NULL AND TRIM(team_basket) != ''
    AND DATE(scheduled_date) < DATE('2018-03-15')
    AND shot_made IS NOT NULL
)

-- Calculate average adjusted coordinates per shot_type
, avg_coordinates AS (
  SELECT
    shot_type,
    ROUND(AVG(adjusted_x_coordinate), 4) AS avg_adjusted_x_coordinate,
    ROUND(AVG(adjusted_y_coordinate), 4) AS avg_adjusted_y_coordinate
  FROM shots_data
  GROUP BY shot_type
)

-- Calculate average shot attempts and successful shots per team per shot_type
, avg_shots_per_team AS (
  SELECT
    shot_type,
    ROUND(AVG(shot_attempts), 4) AS avg_shot_attempts,
    ROUND(AVG(successful_shots), 4) AS avg_successful_shots
  FROM (
    SELECT
      team_id,
      shot_type,
      COUNT(*) AS shot_attempts,
      SUM(CASE WHEN shot_made = TRUE THEN 1 ELSE 0 END) AS successful_shots
    FROM shots_data
    GROUP BY team_id, shot_type
  )
  GROUP BY shot_type
)

SELECT
  ac.shot_type,
  ac.avg_adjusted_x_coordinate,
  ac.avg_adjusted_y_coordinate,
  ast.avg_shot_attempts,
  ast.avg_successful_shots
FROM avg_coordinates ac
JOIN avg_shots_per_team ast USING (shot_type)
ORDER BY ac.shot_type;