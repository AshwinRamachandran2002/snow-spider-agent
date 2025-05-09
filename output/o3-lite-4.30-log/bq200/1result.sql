/* Hardest‑throwing pitcher for every MLB team – regular season + post‑season */
WITH pitches AS (
  SELECT
    /* team the pitcher was playing for in the game */
    CASE
      WHEN pitcherId IN UNNEST([
        homeFielder1, homeFielder2, homeFielder3, homeFielder4, homeFielder5, homeFielder6,
        homeFielder7, homeFielder8, homeFielder9, homeFielder10, homeFielder11, homeFielder12,
        homeBatter1 , homeBatter2 , homeBatter3 , homeBatter4 , homeBatter5 , homeBatter6 ,
        homeBatter7 , homeBatter8 , homeBatter9
      ]) THEN homeTeamId
      WHEN pitcherId IN UNNEST([
        awayFielder1, awayFielder2, awayFielder3, awayFielder4, awayFielder5, awayFielder6,
        awayFielder7, awayFielder8, awayFielder9, awayFielder10, awayFielder11, awayFielder12,
        awayBatter1 , awayBatter2 , awayBatter3 , awayBatter4 , awayBatter5 , awayBatter6 ,
        awayBatter7 , awayBatter8 , awayBatter9
      ]) THEN awayTeamId
    END                                                AS team,
    pitcherId,
    CONCAT(pitcherFirstName, ' ', pitcherLastName)     AS pitcher_name,
    CAST(pitchSpeed AS NUMERIC)                        AS pitchSpeed
  FROM (
    SELECT * FROM `bigquery-public-data.baseball.games_wide`
    UNION ALL
    SELECT * FROM `bigquery-public-data.baseball.games_post_wide`
  )
  /* keep only plausible, non‑zero radar‑gun readings */
  WHERE pitchSpeed BETWEEN 40 AND 110
),
per_pitcher AS (
  /* best speed each pitcher achieved for that specific team */
  SELECT
    team,
    pitcherId,
    ANY_VALUE(pitcher_name)       AS pitcher_name,
    MAX(pitchSpeed)               AS max_pitch_speed_mph
  FROM pitches
  WHERE team IS NOT NULL
  GROUP BY team, pitcherId
),
team_fastest AS (
  /* choose the single hardest thrower for every franchise */
  SELECT
    team,
    FIRST_VALUE(pitcher_name)  OVER w  AS pitcher_name,
    MAX(max_pitch_speed_mph)   OVER w  AS max_pitch_speed_mph
  FROM per_pitcher
  WINDOW w AS (PARTITION BY team ORDER BY max_pitch_speed_mph DESC, pitcherId)
)
SELECT DISTINCT
  team,
  pitcher_name,
  ROUND(max_pitch_speed_mph, 4) AS max_pitch_speed_mph
FROM team_fastest
ORDER BY team;