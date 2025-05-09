WITH combined AS (      -- regular‑season + post‑season pitch events
  SELECT * FROM `bigquery-public-data.baseball.games_wide`
  UNION ALL
  SELECT * FROM `bigquery-public-data.baseball.games_post_wide`
),
plays AS (              -- keep only rows that really contain a pitch
  SELECT
    *,
    ARRAY[                                                 -- all home‑side players this half‑inning
      homeFielder1,homeFielder2,homeFielder3,homeFielder4,homeFielder5,homeFielder6,
      homeFielder7,homeFielder8,homeFielder9,homeFielder10,homeFielder11,homeFielder12,
      homeBatter1,homeBatter2,homeBatter3,homeBatter4,homeBatter5,homeBatter6,
      homeBatter7,homeBatter8,homeBatter9
    ]             AS home_players,
    ARRAY[                                                 -- all away‑side players this half‑inning
      awayFielder1,awayFielder2,awayFielder3,awayFielder4,awayFielder5,awayFielder6,
      awayFielder7,awayFielder8,awayFielder9,awayFielder10,awayFielder11,awayFielder12,
      awayBatter1,awayBatter2,awayBatter3,awayBatter4,awayBatter5,awayBatter6,
      awayBatter7,awayBatter8,awayBatter9
    ]             AS away_players
  FROM combined
  WHERE pitchSpeed > 0                    -- non‑zero, therefore valid
    AND pitcherId IS NOT NULL
    AND pitcherId <> ''
),
eligible AS (          -- assign each pitch to the team for which the pitcher is on the field
  SELECT
    CASE
      WHEN pitcherId IN UNNEST(home_players) THEN homeTeamId
      WHEN pitcherId IN UNNEST(away_players) THEN awayTeamId
    END                                          AS teamId,
    CASE
      WHEN pitcherId IN UNNEST(home_players) THEN homeTeamName
      WHEN pitcherId IN UNNEST(away_players) THEN awayTeamName
    END                                          AS teamName,
    pitchSpeed,
    pitcherId,
    pitcherFirstName,
    pitcherLastName
  FROM plays
  WHERE pitcherId IN UNNEST(home_players)
     OR pitcherId IN UNNEST(away_players)        -- keep only rows where check succeeds
),
ranked AS (           -- pick fastest pitch for each team
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY teamId ORDER BY pitchSpeed DESC) AS rn
  FROM eligible
)
SELECT
  teamId,
  teamName,
  pitcherId,
  CONCAT(pitcherFirstName,' ',pitcherLastName) AS pitcherName,
  pitchSpeed                                   AS maxPitchSpeed
FROM ranked
WHERE rn = 1
ORDER BY maxPitchSpeed DESC;