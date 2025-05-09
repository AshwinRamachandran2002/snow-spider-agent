/*  Fastest valid pitch ( > 0 mph ) thrown for every team, regular‑season +
    post‑season combined.  
    We first union both “wide” pitch‑by‑pitch tables, build the list of
    players that belong to the home / away teams for the current row,
    keep only the pitches whose pitcherId can be verified to be on
    the corresponding team roster in that game, then pick the highest
    speed per team.                                                      */
WITH all_pitches AS (            -- regular season + post‑season
  SELECT
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    CAST(pitchSpeed AS INT64)   AS pitchSpeed,
    homeTeamId,
    homeTeamName,
    awayTeamId,
    awayTeamName,

    -- lists of players that belong to each side in the current game
    ARRAY<STRING>[homeFielder1 ,homeFielder2 ,homeFielder3 ,homeFielder4 ,
                  homeFielder5 ,homeFielder6 ,homeFielder7 ,homeFielder8 ,
                  homeFielder9 ,homeFielder10,homeFielder11,homeFielder12,
                  homeBatter1  ,homeBatter2  ,homeBatter3  ,homeBatter4  ,
                  homeBatter5  ,homeBatter6  ,homeBatter7  ,homeBatter8  ,
                  homeBatter9 ]                                            AS home_players,
    ARRAY<STRING>[awayFielder1 ,awayFielder2 ,awayFielder3 ,awayFielder4 ,
                  awayFielder5 ,awayFielder6 ,awayFielder7 ,awayFielder8 ,
                  awayFielder9 ,awayFielder10,awayFielder11,awayFielder12,
                  awayBatter1  ,awayBatter2  ,awayBatter3  ,awayBatter4  ,
                  awayBatter5  ,awayBatter6  ,awayBatter7  ,awayBatter8  ,
                  awayBatter9 ]                                            AS away_players
  FROM `bigquery-public-data.baseball.games_wide`

  UNION ALL

  SELECT
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    CAST(pitchSpeed AS INT64)   AS pitchSpeed,
    homeTeamId,
    homeTeamName,
    awayTeamId,
    awayTeamName,

    ARRAY<STRING>[homeFielder1 ,homeFielder2 ,homeFielder3 ,homeFielder4 ,
                  homeFielder5 ,homeFielder6 ,homeFielder7 ,homeFielder8 ,
                  homeFielder9 ,homeFielder10,homeFielder11,homeFielder12,
                  homeBatter1  ,homeBatter2  ,homeBatter3  ,homeBatter4  ,
                  homeBatter5  ,homeBatter6  ,homeBatter7  ,homeBatter8  ,
                  homeBatter9 ]                                            AS home_players,
    ARRAY<STRING>[awayFielder1 ,awayFielder2 ,awayFielder3 ,awayFielder4 ,
                  awayFielder5 ,awayFielder6 ,awayFielder7 ,awayFielder8 ,
                  awayFielder9 ,awayFielder10,awayFielder11,awayFielder12,
                  awayBatter1  ,awayBatter2  ,awayBatter3  ,awayBatter4  ,
                  awayBatter5  ,awayBatter6  ,awayBatter7  ,awayBatter8  ,
                  awayBatter9 ]                                            AS away_players
  FROM `bigquery-public-data.baseball.games_post_wide`
),

/* determine for which team (home / away) the pitcher can be verified to
   appear in the game‑level player lists                                 */
identified_team AS (
  SELECT
    CASE
      WHEN EXISTS (SELECT 1 FROM UNNEST(home_players) p WHERE p = pitcherId)
           THEN homeTeamId
      WHEN EXISTS (SELECT 1 FROM UNNEST(away_players) p WHERE p = pitcherId)
           THEN awayTeamId
      ELSE NULL
    END                                                  AS teamId,

    CASE
      WHEN EXISTS (SELECT 1 FROM UNNEST(home_players) p WHERE p = pitcherId)
           THEN homeTeamName
      WHEN EXISTS (SELECT 1 FROM UNNEST(away_players) p WHERE p = pitcherId)
           THEN awayTeamName
      ELSE NULL
    END                                                  AS teamName,

    pitcherId,
    CONCAT(pitcherFirstName,' ',pitcherLastName)         AS pitcherName,
    pitchSpeed
  FROM all_pitches
  WHERE pitchSpeed > 0                                        -- exclude invalid / zero
),

/*  max speed for every (team , pitcher) pair */
pitcher_team_speed AS (
  SELECT
    teamId,
    teamName,
    pitcherId,
    pitcherName,
    MAX(pitchSpeed) AS max_speed
  FROM identified_team
  WHERE teamId IS NOT NULL                                   -- must be verified
  GROUP BY teamId, teamName, pitcherId, pitcherName
),

/*  pick the hardest thrower for each team */
team_hardest_thrower AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY teamId ORDER BY max_speed DESC) AS rn
  FROM pitcher_team_speed
)

SELECT
  teamId          AS team_id,
  teamName        AS team_name,
  pitcherId       AS pitcher_id,
  pitcherName     AS pitcher_name,
  max_speed       AS highest_valid_pitch_speed
FROM team_hardest_thrower
WHERE rn = 1                   -- top pitcher per team
ORDER BY team_name;