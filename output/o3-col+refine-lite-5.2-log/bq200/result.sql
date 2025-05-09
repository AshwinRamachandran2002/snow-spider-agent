/* fastest legitimate pitch (speed > 0) recorded for every club
   – regular‑season + post‑season combined                                   */

WITH ------------------------------------------------------------ REGULAR
regular AS (
  SELECT
    /* identify which club the pitcher is working for in THIS plate‑appearance */
    CASE
      WHEN pitcherId IN (
           homeFielder1, homeFielder2, homeFielder3, homeFielder4, homeFielder5, homeFielder6,
           homeFielder7, homeFielder8, homeFielder9, homeFielder10, homeFielder11, homeFielder12
         )
           THEN homeTeamId
      WHEN pitcherId IN (
           awayFielder1, awayFielder2, awayFielder3, awayFielder4, awayFielder5, awayFielder6,
           awayFielder7, awayFielder8, awayFielder9, awayFielder10, awayFielder11, awayFielder12
         )
           THEN awayTeamId
    END                                                AS teamId ,
    pitcherId,
    pitchSpeed,
    /* keep a few columns so we can later show names */
    pitcherFirstName , pitcherLastName,
    homeTeamId , homeTeamName,
    awayTeamId , awayTeamName
  FROM  `bigquery-public-data.baseball.games_wide`
  WHERE pitchSpeed > 0                                   -- discard missing / bad values
),

---------------------------------------------------------------- POST‑SEASON
post AS (
  SELECT
    CASE
      WHEN pitcherId IN (
           homeFielder1, homeFielder2, homeFielder3, homeFielder4, homeFielder5, homeFielder6,
           homeFielder7, homeFielder8, homeFielder9, homeFielder10, homeFielder11, homeFielder12
         )
           THEN homeTeamId
      WHEN pitcherId IN (
           awayFielder1, awayFielder2, awayFielder3, awayFielder4, awayFielder5, awayFielder6,
           awayFielder7, awayFielder8, awayFielder9, awayFielder10, awayFielder11, awayFielder12
         )
           THEN awayTeamId
    END                                                AS teamId ,
    pitcherId,
    pitchSpeed,
    pitcherFirstName , pitcherLastName,
    homeTeamId , homeTeamName,
    awayTeamId , awayTeamName
  FROM  `bigquery-public-data.baseball.games_post_wide`
  WHERE pitchSpeed > 0
),

---------------------------------------------------------------- UNIONED, ONLY ROWS
all_games AS (
  SELECT * FROM regular
  UNION ALL
  SELECT * FROM post
),
valid_games AS (
  SELECT *
  FROM   all_games
  WHERE  teamId IS NOT NULL                      -- keep rows where pitcher→team was identified
),

---------------------------------------------------------------- MAX SPEED PER PITCHER / TEAM
pitcher_team_max AS (
  SELECT
    teamId,
    pitcherId,
    MAX(pitchSpeed)            AS max_pitch_speed
  FROM   valid_games
  GROUP  BY teamId, pitcherId
),

---------------------------------------------------------------- CHOOSE FASTEST PITCHER PER TEAM
team_best AS (
  SELECT
    pt.teamId,
    pt.pitcherId,
    pt.max_pitch_speed,
    /* attach readable names using any matching row */
    ANY_VALUE(
       CASE
         WHEN vg.homeTeamId = pt.teamId THEN vg.homeTeamName
         WHEN vg.awayTeamId = pt.teamId THEN vg.awayTeamName
       END)                              AS teamName,
    ANY_VALUE(CONCAT(vg.pitcherFirstName,' ',vg.pitcherLastName))
                                         AS pitcherFullName,
    RANK() OVER(PARTITION BY pt.teamId
                ORDER BY pt.max_pitch_speed DESC) AS rnk
  FROM   pitcher_team_max AS pt
  JOIN   valid_games     AS vg
         ON  pt.teamId   = vg.teamId
         AND pt.pitcherId= vg.pitcherId
  GROUP  BY pt.teamId, pt.pitcherId, pt.max_pitch_speed
)

---------------------------------------------------------------- FINAL OUTPUT
SELECT
  teamId,
  teamName,
  pitcherId,
  pitcherFullName,
  max_pitch_speed AS fastest_valid_pitch
FROM   team_best
WHERE  rnk = 1                                  -- top pitcher per club
ORDER  BY fastest_valid_pitch DESC;