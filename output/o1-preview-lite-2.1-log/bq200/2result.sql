WITH pitch_speeds AS (
  SELECT
    CASE WHEN inningHalf = 'top' THEN homeTeamName ELSE awayTeamName END AS TeamName,
    pitcherId,
    CONCAT(pitcherFirstName, ' ', pitcherLastName) AS PitcherName,
    pitchSpeed
  FROM `bigquery-public-data.baseball.games_wide`
  WHERE pitchSpeed > 0 AND pitchSpeed <= 105

  UNION ALL

  SELECT
    CASE WHEN inningHalf = 'top' THEN homeTeamName ELSE awayTeamName END AS TeamName,
    pitcherId,
    CONCAT(pitcherFirstName, ' ', pitcherLastName) AS PitcherName,
    pitchSpeed
  FROM `bigquery-public-data.baseball.games_post_wide`
  WHERE pitchSpeed > 0 AND pitchSpeed <= 105
),

max_pitch_speeds AS (
  SELECT
    TeamName,
    pitcherId,
    PitcherName,
    MAX(pitchSpeed) AS MaxPitchSpeed
  FROM pitch_speeds
  GROUP BY TeamName, pitcherId, PitcherName
),

fastest_pitchers AS (
  SELECT
    TeamName,
    PitcherName,
    MaxPitchSpeed,
    ROW_NUMBER() OVER (PARTITION BY TeamName ORDER BY MaxPitchSpeed DESC, PitcherName) AS rn
  FROM max_pitch_speeds
)

SELECT
  TeamName,
  PitcherName,
  MaxPitchSpeed
FROM fastest_pitchers
WHERE rn = 1
ORDER BY TeamName;