/* -----------------------------------------------------------
   For every MLB club (regular-season + post-season 2016 data),
   find the hardest-throwing pitcher who actually appeared
   on the field for that team in the play where the pitch
   was recorded.
------------------------------------------------------------*/
WITH all_pitches AS (
  -- 1) Regular-season pitches
  SELECT
    /* derive the team the pitcher was playing for */
    CASE
      WHEN pitcherId IN (awayFielder1,awayFielder2,awayFielder3,awayFielder4,
                         awayFielder5,awayFielder6,awayFielder7,awayFielder8,
                         awayFielder9,awayFielder10,awayFielder11,awayFielder12)
        THEN awayTeamId
      WHEN pitcherId IN (homeFielder1,homeFielder2,homeFielder3,homeFielder4,
                         homeFielder5,homeFielder6,homeFielder7,homeFielder8,
                         homeFielder9,homeFielder10,homeFielder11,homeFielder12)
        THEN homeTeamId
    END                                   AS teamId,
    pitcherId,
    CONCAT(pitcherFirstName,' ',pitcherLastName) AS pitcherName,
    pitchSpeed
  FROM `bigquery-public-data.baseball.games_wide`
  WHERE pitchSpeed > 0                       -- keep only timed pitches

  UNION ALL

  -- 2) Post-season pitches
  SELECT
    CASE
      WHEN pitcherId IN (awayFielder1,awayFielder2,awayFielder3,awayFielder4,
                         awayFielder5,awayFielder6,awayFielder7,awayFielder8,
                         awayFielder9,awayFielder10,awayFielder11,awayFielder12)
        THEN awayTeamId
      WHEN pitcherId IN (homeFielder1,homeFielder2,homeFielder3,homeFielder4,
                         homeFielder5,homeFielder6,homeFielder7,homeFielder8,
                         homeFielder9,homeFielder10,homeFielder11,homeFielder12)
        THEN homeTeamId
    END                                   AS teamId,
    pitcherId,
    CONCAT(pitcherFirstName,' ',pitcherLastName) AS pitcherName,
    pitchSpeed
  FROM `bigquery-public-data.baseball.games_post_wide`
  WHERE pitchSpeed > 0
),
/* ----------------------------------------------------------------
   Keep only pitches where the pitcher–team relationship could be
   confirmed (teamId not NULL), then get each pitcher’s top speed
   for that team.
-----------------------------------------------------------------*/
per_pitcher_team AS (
  SELECT
    teamId,
    pitcherId,
    pitcherName,
    MAX(pitchSpeed) AS max_speed
  FROM all_pitches
  WHERE teamId IS NOT NULL
  GROUP BY teamId, pitcherId, pitcherName
),
/* ----------------------------------------------------------------
   Rank pitchers inside each team by their best velocity and keep
   the #1 (hardest thrower) for every club.
-----------------------------------------------------------------*/
hardest_by_team AS (
  SELECT
    teamId,
    pitcherId,
    pitcherName,
    max_speed,
    ROW_NUMBER() OVER (PARTITION BY teamId ORDER BY max_speed DESC) AS rn
  FROM per_pitcher_team
)
/* ----------------------------------------------------------------
   Add a readable club name from the schedules table and output.
-----------------------------------------------------------------*/
SELECT
  h.teamId,
  t.teamName,
  h.pitcherId,
  h.pitcherName,
  h.max_speed
FROM hardest_by_team AS h
LEFT JOIN (
    SELECT DISTINCT homeTeamId AS teamId, homeTeamName AS teamName
    FROM `bigquery-public-data.baseball.schedules`
    UNION DISTINCT
    SELECT DISTINCT awayTeamId, awayTeamName
    FROM `bigquery-public-data.baseball.schedules`
) AS t
USING (teamId)
WHERE rn = 1           -- only the top-velocity pitcher per team
ORDER BY teamName;