WITH CombinedData AS (
  SELECT
    CASE
      WHEN LOWER(`inningHalf`) = 'top' THEN `homeTeamName`
      WHEN LOWER(`inningHalf`) = 'bottom' THEN `awayTeamName`
      ELSE NULL
    END AS `TeamName`,
    CONCAT(`pitcherFirstName`, ' ', `pitcherLastName`) AS `PitcherName`,
    `pitchSpeed`
  FROM `bigquery-public-data.baseball.games_wide`
  WHERE `pitchSpeed` IS NOT NULL AND `pitchSpeed` > 0
    AND `pitcherFirstName` IS NOT NULL
    AND `pitcherLastName` IS NOT NULL
    AND (LOWER(`inningHalf`) = 'top' OR LOWER(`inningHalf`) = 'bottom')

  UNION ALL

  SELECT
    CASE
      WHEN LOWER(`inningHalf`) = 'top' THEN `homeTeamName`
      WHEN LOWER(`inningHalf`) = 'bottom' THEN `awayTeamName`
      ELSE NULL
    END AS `TeamName`,
    CONCAT(`pitcherFirstName`, ' ', `pitcherLastName`) AS `PitcherName`,
    `pitchSpeed`
  FROM `bigquery-public-data.baseball.games_post_wide`
  WHERE `pitchSpeed` IS NOT NULL AND `pitchSpeed` > 0
    AND `pitcherFirstName` IS NOT NULL
    AND `pitcherLastName` IS NOT NULL
    AND (LOWER(`inningHalf`) = 'top' OR LOWER(`inningHalf`) = 'bottom')
),

MaxPitchSpeedPerPitcherTeam AS (
  SELECT
    `TeamName`,
    `PitcherName`,
    MAX(`pitchSpeed`) AS `MaxPitchSpeed`
  FROM CombinedData
  GROUP BY `TeamName`, `PitcherName`
),

FastestPitcherPerTeam AS (
  SELECT
    `TeamName`,
    `PitcherName`,
    `MaxPitchSpeed`,
    ROW_NUMBER() OVER (
      PARTITION BY `TeamName`
      ORDER BY `MaxPitchSpeed` DESC
    ) AS `rn`
  FROM MaxPitchSpeedPerPitcherTeam
)

SELECT
  `TeamName`,
  `PitcherName`,
  `MaxPitchSpeed`
FROM FastestPitcherPerTeam
WHERE `rn` = 1
ORDER BY `TeamName`;