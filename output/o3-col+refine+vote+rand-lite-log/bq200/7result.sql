/*  Highest recorded (non-zero) pitch speed for each MLB team (2016 regular- and post-season)
    -------------------------------------------------------------------------------
    • Combines regular-season (`games_wide`) and post-season (`games_post_wide`) plays.
    • Confirms a play belongs to a team only when the pitcherId appears in that club’s
      12 fielder slots (home* or away*).                                            */

WITH union_games AS (            -- bring in only columns we need from both tables
  SELECT
      pitcherId ,
      pitcherFirstName ,
      pitcherLastName ,
      pitchSpeed ,
      homeTeamId , homeTeamName ,
      awayTeamId , awayTeamName ,
      ARRAY<STRING>[homeFielder1 ,homeFielder2 ,homeFielder3 ,homeFielder4 ,homeFielder5 ,
                    homeFielder6 ,homeFielder7 ,homeFielder8 ,homeFielder9 ,homeFielder10 ,
                    homeFielder11,homeFielder12] AS home_fielders ,
      ARRAY<STRING>[awayFielder1 ,awayFielder2 ,awayFielder3 ,awayFielder4 ,awayFielder5 ,
                    awayFielder6 ,awayFielder7 ,awayFielder8 ,awayFielder9 ,awayFielder10 ,
                    awayFielder11,awayFielder12] AS away_fielders
  FROM `bigquery-public-data.baseball.games_wide`

  UNION ALL

  SELECT
      pitcherId ,
      pitcherFirstName ,
      pitcherLastName ,
      pitchSpeed ,
      homeTeamId , homeTeamName ,
      awayTeamId , awayTeamName ,
      ARRAY<STRING>[homeFielder1 ,homeFielder2 ,homeFielder3 ,homeFielder4 ,homeFielder5 ,
                    homeFielder6 ,homeFielder7 ,homeFielder8 ,homeFielder9 ,homeFielder10 ,
                    homeFielder11,homeFielder12] ,
      ARRAY<STRING>[awayFielder1 ,awayFielder2 ,awayFielder3 ,awayFielder4 ,awayFielder5 ,
                    awayFielder6 ,awayFielder7 ,awayFielder8 ,awayFielder9 ,awayFielder10 ,
                    awayFielder11,awayFielder12]
  FROM `bigquery-public-data.baseball.games_post_wide`
),

plays AS (                       -- keep only rows with a valid (non-zero) pitch speed
  SELECT
    CASE
      WHEN pitcherId IN UNNEST(home_fielders) THEN homeTeamId
      WHEN pitcherId IN UNNEST(away_fielders) THEN awayTeamId
    END                                             AS teamId ,

    CASE
      WHEN pitcherId IN UNNEST(home_fielders) THEN homeTeamName
      WHEN pitcherId IN UNNEST(away_fielders) THEN awayTeamName
    END                                             AS teamName ,

    pitcherId ,
    CONCAT(pitcherFirstName,' ',pitcherLastName)    AS pitcher_name ,
    pitchSpeed
  FROM union_games
  WHERE pitchSpeed > 0
),

max_per_pitcher_team AS (        -- best speed each pitcher reached for every team
  SELECT
    teamId , teamName ,
    pitcherId , pitcher_name ,
    MAX(pitchSpeed) AS max_speed
  FROM plays
  WHERE teamId IS NOT NULL
  GROUP BY teamId , teamName , pitcherId , pitcher_name
),

ranked AS (                      -- choose the single hardest-thrower for every team
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY teamId ORDER BY max_speed DESC, pitcher_name) AS rn
  FROM   max_per_pitcher_team
)

SELECT
  teamId ,
  teamName ,
  pitcherId ,
  pitcher_name ,
  max_speed
FROM ranked
WHERE rn = 1
ORDER BY teamName;