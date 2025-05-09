WITH all_pitch_events AS (
  -- regular‑season pitches
  SELECT
    gameId,
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    pitchSpeed,
    homeTeamId,
    awayTeamId,
    ARRAY<STRING>[
      homeFielder1, homeFielder2, homeFielder3, homeFielder4, homeFielder5, homeFielder6,
      homeFielder7, homeFielder8, homeFielder9, homeFielder10, homeFielder11, homeFielder12,
      homeBatter1,  homeBatter2,  homeBatter3,  homeBatter4,  homeBatter5,
      homeBatter6,  homeBatter7,  homeBatter8,  homeBatter9
    ] AS home_players,
    ARRAY<STRING>[
      awayFielder1, awayFielder2, awayFielder3, awayFielder4, awayFielder5, awayFielder6,
      awayFielder7, awayFielder8, awayFielder9, awayFielder10, awayFielder11, awayFielder12,
      awayBatter1,  awayBatter2,  awayBatter3,  awayBatter4,  awayBatter5,
      awayBatter6,  awayBatter7,  awayBatter8,  awayBatter9
    ] AS away_players
  FROM `bigquery-public-data.baseball.games_wide`
  WHERE pitchSpeed > 0

  UNION ALL

  -- post‑season pitches
  SELECT
    gameId,
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    pitchSpeed,
    homeTeamId,
    awayTeamId,
    ARRAY<STRING>[
      homeFielder1, homeFielder2, homeFielder3, homeFielder4, homeFielder5, homeFielder6,
      homeFielder7, homeFielder8, homeFielder9, homeFielder10, homeFielder11, homeFielder12,
      homeBatter1,  homeBatter2,  homeBatter3,  homeBatter4,  homeBatter5,
      homeBatter6,  homeBatter7,  homeBatter8,  homeBatter9
    ] AS home_players,
    ARRAY<STRING>[
      awayFielder1, awayFielder2, awayFielder3, awayFielder4, awayFielder5, awayFielder6,
      awayFielder7, awayFielder8, awayFielder9, awayFielder10, awayFielder11, awayFielder12,
      awayBatter1,  awayBatter2,  awayBatter3,  awayBatter4,  awayBatter5,
      awayBatter6,  awayBatter7,  awayBatter8,  awayBatter9
    ] AS away_players
  FROM `bigquery-public-data.baseball.games_post_wide`
  WHERE pitchSpeed > 0
),

-- keep only pitches where the pitcher is confirmed to be on the
-- corresponding team’s on‑field or batting list in that game
confirmed_team_pitches AS (
  SELECT
    CASE
      WHEN pitcherId IN UNNEST(home_players) THEN homeTeamId
      WHEN pitcherId IN UNNEST(away_players) THEN awayTeamId
      ELSE NULL
    END                                              AS teamId,
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    pitchSpeed
  FROM all_pitch_events
  WHERE pitchSpeed IS NOT NULL
),

-- best speed each pitcher has recorded while playing for a given team
pitcher_team_max AS (
  SELECT
    teamId,
    pitcherId,
    ANY_VALUE(pitcherFirstName) AS pitcherFirstName,
    ANY_VALUE(pitcherLastName)  AS pitcherLastName,
    MAX(pitchSpeed)             AS max_pitch_speed
  FROM confirmed_team_pitches
  WHERE teamId IS NOT NULL
  GROUP BY teamId, pitcherId
),

-- pick the fastest pitcher for every team
team_fastest_pitcher AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY teamId ORDER BY max_pitch_speed DESC) AS rn
  FROM pitcher_team_max
)

SELECT
  teamId,
  CONCAT(pitcherFirstName, ' ', pitcherLastName) AS pitcher_full_name,
  max_pitch_speed
FROM team_fastest_pitcher
WHERE rn = 1
ORDER BY max_pitch_speed DESC;