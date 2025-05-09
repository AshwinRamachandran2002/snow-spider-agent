WITH all_pitches AS (
  SELECT
    homeTeamId AS Team_ID,
    pitcherId,
    CONCAT(pitcherFirstName, ' ', pitcherLastName) AS Pitcher_Name,
    pitchSpeed
  FROM
    `bigquery-public-data.baseball.games_wide`
  WHERE
    pitchSpeed > 0
    AND pitcherId IN (
      homeFielder1, homeFielder2, homeFielder3, homeFielder4, homeFielder5, homeFielder6,
      homeFielder7, homeFielder8, homeFielder9, homeFielder10, homeFielder11, homeFielder12
    )
  UNION ALL
  SELECT
    awayTeamId AS Team_ID,
    pitcherId,
    CONCAT(pitcherFirstName, ' ', pitcherLastName) AS Pitcher_Name,
    pitchSpeed
  FROM
    `bigquery-public-data.baseball.games_wide`
  WHERE
    pitchSpeed > 0
    AND pitcherId IN (
      awayFielder1, awayFielder2, awayFielder3, awayFielder4, awayFielder5, awayFielder6,
      awayFielder7, awayFielder8, awayFielder9, awayFielder10, awayFielder11, awayFielder12
    )
  UNION ALL
  SELECT
    homeTeamId AS Team_ID,
    pitcherId,
    CONCAT(pitcherFirstName, ' ', pitcherLastName) AS Pitcher_Name,
    pitchSpeed
  FROM
    `bigquery-public-data.baseball.games_post_wide`
  WHERE
    pitchSpeed > 0
    AND pitcherId IN (
      homeFielder1, homeFielder2, homeFielder3, homeFielder4, homeFielder5, homeFielder6,
      homeFielder7, homeFielder8, homeFielder9, homeFielder10, homeFielder11, homeFielder12
    )
  UNION ALL
  SELECT
    awayTeamId AS Team_ID,
    pitcherId,
    CONCAT(pitcherFirstName, ' ', pitcherLastName) AS Pitcher_Name,
    pitchSpeed
  FROM
    `bigquery-public-data.baseball.games_post_wide`
  WHERE
    pitchSpeed > 0
    AND pitcherId IN (
      awayFielder1, awayFielder2, awayFielder3, awayFielder4, awayFielder5, awayFielder6,
      awayFielder7, awayFielder8, awayFielder9, awayFielder10, awayFielder11, awayFielder12
    )
),
max_pitcher_speed AS (
  SELECT
    Team_ID,
    Pitcher_Name,
    MAX(pitchSpeed) AS Max_Pitch_Speed
  FROM
    all_pitches
  GROUP BY
    Team_ID, Pitcher_Name
),
ranked_pitchers AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY Team_ID ORDER BY Max_Pitch_Speed DESC) AS rn
  FROM
    max_pitcher_speed
)
SELECT
  Team_ID,
  Pitcher_Name,
  Max_Pitch_Speed
FROM
  ranked_pitchers
WHERE
  rn = 1
ORDER BY
  Team_ID;