-- Pitcher with the highest (non‑zero) pitch speed for every team (regular season + post‑season)
WITH all_pitches AS (
  -- Regular season
  SELECT
    pitchSpeed,
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    homeTeamId,
    awayTeamId,
    ARRAY<STRING>[
      homeFielder1,homeFielder2,homeFielder3,homeFielder4,homeFielder5,homeFielder6,
      homeFielder7,homeFielder8,homeFielder9,homeFielder10,homeFielder11,homeFielder12
    ] AS home_fielders,
    ARRAY<STRING>[
      awayFielder1,awayFielder2,awayFielder3,awayFielder4,awayFielder5,awayFielder6,
      awayFielder7,awayFielder8,awayFielder9,awayFielder10,awayFielder11,awayFielder12
    ] AS away_fielders
  FROM `bigquery-public-data.baseball.games_wide`
  
  UNION ALL
  
  -- Post‑season
  SELECT
    pitchSpeed,
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    homeTeamId,
    awayTeamId,
    ARRAY<STRING>[
      homeFielder1,homeFielder2,homeFielder3,homeFielder4,homeFielder5,homeFielder6,
      homeFielder7,homeFielder8,homeFielder9,homeFielder10,homeFielder11,homeFielder12
    ] AS home_fielders,
    ARRAY<STRING>[
      awayFielder1,awayFielder2,awayFielder3,awayFielder4,awayFielder5,awayFielder6,
      awayFielder7,awayFielder8,awayFielder9,awayFielder10,awayFielder11,awayFielder12
    ] AS away_fielders
  FROM `bigquery-public-data.baseball.games_post_wide`
),

/* Validate that the pitcher actually appeared for the club
   (i.e., his ID is present in that game’s home/away fielder list) */
validated AS (
  SELECT
    CASE
      WHEN EXISTS (SELECT 1 FROM UNNEST(home_fielders) AS f WHERE f = pitcherId) THEN homeTeamId
      WHEN EXISTS (SELECT 1 FROM UNNEST(away_fielders) AS f WHERE f = pitcherId) THEN awayTeamId
    END                         AS teamId,
    pitcherId,
    ANY_VALUE(pitcherFirstName) AS firstName,
    ANY_VALUE(pitcherLastName)  AS lastName,
    MAX(pitchSpeed)             AS maxSpeed    -- fastest pitch this pitcher threw for that club
  FROM all_pitches
  WHERE pitchSpeed > 0
  GROUP BY teamId, pitcherId
),

/* For each team, keep the single fastest pitcher (ties broken by pitcherId) */
club_fastest AS (
  SELECT
    teamId,
    pitcherId,
    firstName,
    lastName,
    maxSpeed,
    ROW_NUMBER() OVER (PARTITION BY teamId ORDER BY maxSpeed DESC, pitcherId) AS rn
  FROM validated
  WHERE teamId IS NOT NULL
)

SELECT
  teamId,
  CONCAT(firstName, ' ', lastName) AS pitcherFullName,
  maxSpeed                         AS maxPitchSpeed
FROM club_fastest
WHERE rn = 1
ORDER BY teamId;