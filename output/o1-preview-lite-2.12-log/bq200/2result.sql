WITH combined_data AS (
  SELECT
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    pitchSpeed,
    CASE
      WHEN pitcherId IN (homeFielder1, homeFielder2, homeFielder3, homeFielder4, homeFielder5, homeFielder6, homeFielder7, homeFielder8, homeFielder9) THEN homeTeamId
      WHEN pitcherId IN (awayFielder1, awayFielder2, awayFielder3, awayFielder4, awayFielder5, awayFielder6, awayFielder7, awayFielder8, awayFielder9) THEN awayTeamId
      ELSE NULL
    END AS teamId
  FROM `bigquery-public-data.baseball.games_wide`
  WHERE pitchSpeed > 0 AND pitcherId IS NOT NULL

  UNION ALL

  SELECT
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    pitchSpeed,
    CASE
      WHEN pitcherId IN (homeFielder1, homeFielder2, homeFielder3, homeFielder4, homeFielder5, homeFielder6, homeFielder7, homeFielder8, homeFielder9) THEN homeTeamId
      WHEN pitcherId IN (awayFielder1, awayFielder2, awayFielder3, awayFielder4, awayFielder5, awayFielder6, awayFielder7, awayFielder8, awayFielder9) THEN awayTeamId
      ELSE NULL
    END AS teamId
  FROM `bigquery-public-data.baseball.games_post_wide`
  WHERE pitchSpeed > 0 AND pitcherId IS NOT NULL
),

pitcher_team_max AS (
  SELECT
    teamId,
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    MAX(pitchSpeed) AS Max_Pitch_Speed
  FROM combined_data
  WHERE teamId IS NOT NULL
  GROUP BY teamId, pitcherId, pitcherFirstName, pitcherLastName
),

team_top_pitcher AS (
  SELECT
    teamId,
    pitcherFirstName,
    pitcherLastName,
    Max_Pitch_Speed,
    ROW_NUMBER() OVER (PARTITION BY teamId ORDER BY Max_Pitch_Speed DESC, pitcherId) AS rn
  FROM pitcher_team_max
)

SELECT
  teamId AS Team_ID,
  CONCAT(pitcherFirstName, ' ', pitcherLastName) AS Pitcher_Name,
  Max_Pitch_Speed
FROM team_top_pitcher
WHERE rn = 1
ORDER BY Max_Pitch_Speed DESC;