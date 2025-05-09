WITH pitcher_speeds AS (
  SELECT
    teamName,
    CONCAT(pitcherFirstName, ' ', pitcherLastName) AS PitcherName,
    MAX(pitchSpeed) AS MaxPitchSpeed
  FROM (
    SELECT
      CASE
        WHEN LOWER(inningHalf) = 'top' THEN homeTeamName
        WHEN LOWER(inningHalf) = 'bottom' THEN awayTeamName
      END AS teamName,
      pitcherFirstName,
      pitcherLastName,
      pitchSpeed
    FROM
      `bigquery-public-data.baseball.games_wide`
    UNION ALL
    SELECT
      CASE
        WHEN LOWER(inningHalf) = 'top' THEN homeTeamName
        WHEN LOWER(inningHalf) = 'bottom' THEN awayTeamName
      END AS teamName,
      pitcherFirstName,
      pitcherLastName,
      pitchSpeed
    FROM
      `bigquery-public-data.baseball.games_post_wide`
  )
  WHERE
    pitchSpeed IS NOT NULL
    AND pitchSpeed > 0
    AND pitcherFirstName IS NOT NULL
    AND pitcherLastName IS NOT NULL
    AND teamName IS NOT NULL
    AND teamName NOT IN ('American League', 'National League')
  GROUP BY
    teamName,
    PitcherName
)
SELECT
  teamName AS TeamName,
  PitcherName,
  MaxPitchSpeed
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY teamName ORDER BY MaxPitchSpeed DESC, PitcherName) AS rn
  FROM
    pitcher_speeds
)
WHERE
  rn = 1
ORDER BY
  TeamName;