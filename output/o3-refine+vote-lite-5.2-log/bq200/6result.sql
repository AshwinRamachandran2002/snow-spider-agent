/* ----------------------------------------------------------
   Fastest valid pitch (speed > 0) thrown for every MLB team
   across both regular‑season and post‑season games.
   A pitch is credited to a team only when the pitcher’s ID
   is found in that game’s corresponding home or away
   fielder lists, ensuring the pitcher really played
   for that team in that game.
-----------------------------------------------------------*/
WITH all_games AS (
  -- Regular‑season rows
  SELECT
      gameId,
      homeTeamId,
      homeTeamName,
      awayTeamId,
      awayTeamName,
      pitcherId,
      pitcherFirstName,
      pitcherLastName,
      CAST(pitchSpeed AS INT64)           AS pitchSpeed,
      [homeFielder1,homeFielder2,homeFielder3,homeFielder4,
       homeFielder5,homeFielder6,homeFielder7,homeFielder8,
       homeFielder9,homeFielder10,homeFielder11,homeFielder12] AS home_fielders,
      [awayFielder1,awayFielder2,awayFielder3,awayFielder4,
       awayFielder5,awayFielder6,awayFielder7,awayFielder8,
       awayFielder9,awayFielder10,awayFielder11,awayFielder12] AS away_fielders
  FROM `bigquery-public-data.baseball.games_wide`

  UNION ALL

  -- Post‑season rows
  SELECT
      gameId,
      homeTeamId,
      homeTeamName,
      awayTeamId,
      awayTeamName,
      pitcherId,
      pitcherFirstName,
      pitcherLastName,
      CAST(pitchSpeed AS INT64)           AS pitchSpeed,
      [homeFielder1,homeFielder2,homeFielder3,homeFielder4,
       homeFielder5,homeFielder6,homeFielder7,homeFielder8,
       homeFielder9,homeFielder10,homeFielder11,homeFielder12],
      [awayFielder1,awayFielder2,awayFielder3,awayFielder4,
       awayFielder5,awayFielder6,awayFielder7,awayFielder8,
       awayFielder9,awayFielder10,awayFielder11,awayFielder12]
  FROM `bigquery-public-data.baseball.games_post_wide`
),

-- Keep only pitches where we can prove the pitcher belonged to
-- the home or away team in that particular game
pitcher_team AS (
  SELECT
    CASE
      WHEN pitcherId IN UNNEST(home_fielders) THEN homeTeamId
      WHEN pitcherId IN UNNEST(away_fielders) THEN awayTeamId
      ELSE NULL
    END                                              AS teamId,
    CASE
      WHEN pitcherId IN UNNEST(home_fielders) THEN homeTeamName
      WHEN pitcherId IN UNNEST(away_fielders) THEN awayTeamName
    END                                              AS teamName,
    pitcherId,
    CONCAT(pitcherFirstName,' ',pitcherLastName)     AS pitcherFullName,
    pitchSpeed
  FROM all_games
  WHERE pitchSpeed > 0           -- ignore zero / missing speeds
),

-- Rank pitches inside each team by speed (and tiebreak by name)
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY teamId
                       ORDER BY pitchSpeed DESC, pitcherFullName) AS rn
  FROM pitcher_team
  WHERE teamId IS NOT NULL
)

-- Final answer: one row per team
SELECT
  teamId,
  teamName,
  pitcherFullName,
  pitchSpeed AS maxPitchSpeed
FROM ranked
WHERE rn = 1          -- fastest pitch per team
ORDER BY teamName;