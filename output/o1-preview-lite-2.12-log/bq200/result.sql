WITH combined_games AS (
  SELECT
    pitcherId,
    CONCAT(pitcherFirstName, ' ', pitcherLastName) AS Pitcher_Name,
    pitchSpeed,
    homeTeamId,
    awayTeamId,
    ARRAY[homeFielder1, homeFielder2, homeFielder3, homeFielder4, homeFielder5,
      homeFielder6, homeFielder7, homeFielder8, homeFielder9, homeFielder10,
      homeFielder11, homeFielder12] AS homeFielderIds,
    ARRAY[awayFielder1, awayFielder2, awayFielder3, awayFielder4, awayFielder5,
      awayFielder6, awayFielder7, awayFielder8, awayFielder9, awayFielder10,
      awayFielder11, awayFielder12] AS awayFielderIds
  FROM `bigquery-public-data.baseball.games_wide`
  UNION ALL
  SELECT
    pitcherId,
    CONCAT(pitcherFirstName, ' ', pitcherLastName) AS Pitcher_Name,
    pitchSpeed,
    homeTeamId,
    awayTeamId,
    ARRAY[homeFielder1, homeFielder2, homeFielder3, homeFielder4, homeFielder5,
      homeFielder6, homeFielder7, homeFielder8, homeFielder9, homeFielder10,
      homeFielder11, homeFielder12] AS homeFielderIds,
    ARRAY[awayFielder1, awayFielder2, awayFielder3, awayFielder4, awayFielder5,
      awayFielder6, awayFielder7, awayFielder8, awayFielder9, awayFielder10,
      awayFielder11, awayFielder12] AS awayFielderIds
  FROM `bigquery-public-data.baseball.games_post_wide`
),
pitcher_team_speeds AS (
  SELECT
    pitcherId,
    Pitcher_Name,
    pitchSpeed,
    CASE
      WHEN pitcherId IN UNNEST(homeFielderIds) THEN homeTeamId
      WHEN pitcherId IN UNNEST(awayFielderIds) THEN awayTeamId
      ELSE NULL
    END AS Team_ID
  FROM combined_games
  WHERE pitchSpeed > 0 AND pitcherId IS NOT NULL
),
pitcher_max_speeds AS (
  SELECT
    Team_ID,
    pitcherId,
    Pitcher_Name,
    MAX(pitchSpeed) AS Max_Pitch_Speed
  FROM pitcher_team_speeds
  WHERE Team_ID IS NOT NULL
  GROUP BY Team_ID, pitcherId, Pitcher_Name
),
team_max_pitchers AS (
  SELECT
    Team_ID,
    Pitcher_Name,
    Max_Pitch_Speed,
    ROW_NUMBER() OVER (PARTITION BY Team_ID ORDER BY Max_Pitch_Speed DESC, Pitcher_Name) AS rn
  FROM pitcher_max_speeds
)
SELECT
  Team_ID,
  Pitcher_Name,
  Max_Pitch_Speed
FROM team_max_pitchers
WHERE rn = 1
ORDER BY Team_ID;