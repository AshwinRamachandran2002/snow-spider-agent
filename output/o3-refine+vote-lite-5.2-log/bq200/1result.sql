/* Highest non‑zero pitch speed recorded for each MLB team
   (regular‑season + post‑season)                                      */
WITH all_pitches AS (          -- 1. union REG and PST pitch events
  SELECT
      gameId,
      pitchSpeed,
      pitcherId,
      pitcherFirstName,
      pitcherLastName,
      homeTeamId , homeTeamName ,
      awayTeamId , awayTeamName ,

      -- every player listed for each side in the row
      ARRAY[
        homeFielder1 , homeFielder2 , homeFielder3 , homeFielder4 , homeFielder5 ,
        homeFielder6 , homeFielder7 , homeFielder8 , homeFielder9 , homeFielder10 ,
        homeFielder11, homeFielder12,
        homeBatter1  , homeBatter2  , homeBatter3  , homeBatter4  , homeBatter5  ,
        homeBatter6  , homeBatter7  , homeBatter8  , homeBatter9
      ] AS home_players,

      ARRAY[
        awayFielder1 , awayFielder2 , awayFielder3 , awayFielder4 , awayFielder5 ,
        awayFielder6 , awayFielder7 , awayFielder8 , awayFielder9 , awayFielder10 ,
        awayFielder11, awayFielder12,
        awayBatter1  , awayBatter2  , awayBatter3  , awayBatter4  , awayBatter5  ,
        awayBatter6  , awayBatter7  , awayBatter8  , awayBatter9
      ] AS away_players
  FROM `bigquery-public-data.baseball.games_wide`

  UNION ALL

  SELECT
      gameId,
      pitchSpeed,
      pitcherId,
      pitcherFirstName,
      pitcherLastName,
      homeTeamId , homeTeamName ,
      awayTeamId , awayTeamName ,

      ARRAY[
        homeFielder1 , homeFielder2 , homeFielder3 , homeFielder4 , homeFielder5 ,
        homeFielder6 , homeFielder7 , homeFielder8 , homeFielder9 , homeFielder10 ,
        homeFielder11, homeFielder12,
        homeBatter1  , homeBatter2  , homeBatter3  , homeBatter4  , homeBatter5  ,
        homeBatter6  , homeBatter7  , homeBatter8  , homeBatter9
      ],
      ARRAY[
        awayFielder1 , awayFielder2 , awayFielder3 , awayFielder4 , awayFielder5 ,
        awayFielder6 , awayFielder7 , awayFielder8 , awayFielder9 , awayFielder10 ,
        awayFielder11, awayFielder12,
        awayBatter1  , awayBatter2  , awayBatter3  , awayBatter4  , awayBatter5  ,
        awayBatter6  , awayBatter7  , awayBatter8  , awayBatter9
      ]
  FROM `bigquery-public-data.baseball.games_post_wide`
),

pitcher_with_team AS (     -- 2. keep only valid speeds and tag with team
  SELECT
      CASE
          WHEN pitcherId IN UNNEST(home_players) THEN homeTeamId
          WHEN pitcherId IN UNNEST(away_players) THEN awayTeamId
      END                                   AS teamId,

      CASE
          WHEN pitcherId IN UNNEST(home_players) THEN homeTeamName
          WHEN pitcherId IN UNNEST(away_players) THEN awayTeamName
      END                                   AS teamName,

      pitcherId,
      CONCAT(pitcherFirstName,' ',pitcherLastName) AS pitcherName,
      pitchSpeed
  FROM all_pitches
  WHERE pitchSpeed > 0
    AND pitcherId IS NOT NULL
    AND (pitcherId IN UNNEST(home_players)
         OR pitcherId IN UNNEST(away_players))     -- ensure club match
),

max_speed_per_team AS (    -- 3. maximum speed for each team
  SELECT
      teamId,
      MAX(pitchSpeed) AS maxSpeed
  FROM pitcher_with_team
  GROUP BY teamId
)

-- 4.  one row per team: pitcher that reached the max speed
SELECT
    team_id,
    team_name,
    pitcher_name,
    max_pitch_speed
FROM (
  SELECT
      m.teamId                     AS team_id,
      pwt.teamName                 AS team_name,
      pwt.pitcherName              AS pitcher_name,
      m.maxSpeed                   AS max_pitch_speed,
      ROW_NUMBER() OVER (PARTITION BY m.teamId
                         ORDER BY pwt.pitcherName) AS rn   -- tie‑breaker
  FROM max_speed_per_team AS m
  JOIN pitcher_with_team  AS pwt
    ON pwt.teamId     = m.teamId
   AND pwt.pitchSpeed = m.maxSpeed
)
WHERE rn = 1
ORDER BY team_name;