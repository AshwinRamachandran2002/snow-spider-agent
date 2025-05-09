WITH union_games AS (
  -- Regular‑season pitches
  SELECT
    gameId,
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    pitchSpeed,
    homeTeamId,
    awayTeamId,
    -- build home / away player rosters for easy membership checks
    [
      homeFielder1,homeFielder2,homeFielder3,homeFielder4,homeFielder5,homeFielder6,
      homeFielder7,homeFielder8,homeFielder9,homeFielder10,homeFielder11,homeFielder12,
      homeBatter1,homeBatter2,homeBatter3,homeBatter4,homeBatter5,homeBatter6,
      homeBatter7,homeBatter8,homeBatter9
    ] AS home_players,
    [
      awayFielder1,awayFielder2,awayFielder3,awayFielder4,awayFielder5,awayFielder6,
      awayFielder7,awayFielder8,awayFielder9,awayFielder10,awayFielder11,awayFielder12,
      awayBatter1,awayBatter2,awayBatter3,awayBatter4,awayBatter5,awayBatter6,
      awayBatter7,awayBatter8,awayBatter9
    ] AS away_players
  FROM `bigquery-public-data.baseball.games_wide`
  WHERE pitchSpeed > 0          -- keep only valid (non‑zero) pitch speeds

  UNION ALL

  -- Post‑season pitches
  SELECT
    gameId,
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    pitchSpeed,
    homeTeamId,
    awayTeamId,
    [
      homeFielder1,homeFielder2,homeFielder3,homeFielder4,homeFielder5,homeFielder6,
      homeFielder7,homeFielder8,homeFielder9,homeFielder10,homeFielder11,homeFielder12,
      homeBatter1,homeBatter2,homeBatter3,homeBatter4,homeBatter5,homeBatter6,
      homeBatter7,homeBatter8,homeBatter9
    ] AS home_players,
    [
      awayFielder1,awayFielder2,awayFielder3,awayFielder4,awayFielder5,awayFielder6,
      awayFielder7,awayFielder8,awayFielder9,awayFielder10,awayFielder11,awayFielder12,
      awayBatter1,awayBatter2,awayBatter3,awayBatter4,awayBatter5,awayBatter6,
      awayBatter7,awayBatter8,awayBatter9
    ] AS away_players
  FROM `bigquery-public-data.baseball.games_post_wide`
  WHERE pitchSpeed > 0
),

-- decide which team the pitcher was throwing for in each pitch
with_team AS (
  SELECT
    *,
    CASE
      WHEN pitcherId IN UNNEST(home_players) THEN homeTeamId
      WHEN pitcherId IN UNNEST(away_players) THEN awayTeamId
      ELSE NULL
    END AS team_id
  FROM union_games
),

-- maximum pitch speed per pitcher per team
pitcher_team_max AS (
  SELECT
    team_id,
    pitcherId,
    MAX(pitchSpeed) AS max_speed,
    ANY_VALUE(CONCAT(pitcherFirstName,' ',pitcherLastName)) AS full_name
  FROM with_team
  WHERE team_id IS NOT NULL            -- keep only rows where team could be confirmed
  GROUP BY team_id, pitcherId
),

-- pick the single fastest pitcher for each team
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY team_id ORDER BY max_speed DESC, full_name) AS rn
  FROM pitcher_team_max
)

SELECT
  team_id        AS teamId,
  full_name      AS pitcherFullName,
  max_speed      AS maxPitchSpeed
FROM ranked
WHERE rn = 1
ORDER BY teamId;