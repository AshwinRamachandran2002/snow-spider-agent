/*  Highest (valid) pitch speed per team – regular- & post-season combined */
WITH regular AS (
  SELECT
    -- decide which roster the pitcher is on
    CASE
      WHEN pitcherId IN (homeFielder1,homeFielder2,homeFielder3,homeFielder4,
                         homeFielder5,homeFielder6,homeFielder7,homeFielder8,
                         homeFielder9,homeFielder10,homeFielder11,homeFielder12)
           THEN homeTeamId ELSE awayTeamId END                                AS team_id,
    CASE
      WHEN pitcherId IN (homeFielder1,homeFielder2,homeFielder3,homeFielder4,
                         homeFielder5,homeFielder6,homeFielder7,homeFielder8,
                         homeFielder9,homeFielder10,homeFielder11,homeFielder12)
           THEN homeTeamName ELSE awayTeamName END                            AS team_name,
    pitcherId,
    CONCAT(pitcherFirstName,' ',pitcherLastName)                              AS pitcher_name,
    pitchSpeed
  FROM `bigquery-public-data.baseball.games_wide`
  WHERE pitchSpeed BETWEEN 1 AND 105      -- keep only realistic, non-zero speeds
    AND (
          pitcherId IN (homeFielder1,homeFielder2,homeFielder3,homeFielder4,
                        homeFielder5,homeFielder6,homeFielder7,homeFielder8,
                        homeFielder9,homeFielder10,homeFielder11,homeFielder12)
       OR pitcherId IN (awayFielder1,awayFielder2,awayFielder3,awayFielder4,
                        awayFielder5,awayFielder6,awayFielder7,awayFielder8,
                        awayFielder9,awayFielder10,awayFielder11,awayFielder12)
        )
),
post AS (
  SELECT
    CASE
      WHEN pitcherId IN (homeFielder1,homeFielder2,homeFielder3,homeFielder4,
                         homeFielder5,homeFielder6,homeFielder7,homeFielder8,
                         homeFielder9,homeFielder10,homeFielder11,homeFielder12)
           THEN homeTeamId ELSE awayTeamId END,
    CASE
      WHEN pitcherId IN (homeFielder1,homeFielder2,homeFielder3,homeFielder4,
                         homeFielder5,homeFielder6,homeFielder7,homeFielder8,
                         homeFielder9,homeFielder10,homeFielder11,homeFielder12)
           THEN homeTeamName ELSE awayTeamName END,
    pitcherId,
    CONCAT(pitcherFirstName,' ',pitcherLastName),
    pitchSpeed
  FROM `bigquery-public-data.baseball.games_post_wide`
  WHERE pitchSpeed BETWEEN 1 AND 105
    AND (
          pitcherId IN (homeFielder1,homeFielder2,homeFielder3,homeFielder4,
                        homeFielder5,homeFielder6,homeFielder7,homeFielder8,
                        homeFielder9,homeFielder10,homeFielder11,homeFielder12)
       OR pitcherId IN (awayFielder1,awayFielder2,awayFielder3,awayFielder4,
                        awayFielder5,awayFielder6,awayFielder7,awayFielder8,
                        awayFielder9,awayFielder10,awayFielder11,awayFielder12)
        )
),
all_pitches AS (
  SELECT * FROM regular
  UNION ALL
  SELECT * FROM post
),
ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY team_id ORDER BY pitchSpeed DESC) AS rn
  FROM all_pitches
)
SELECT
  team_id,
  team_name,
  pitcherId          AS pitcher_id,
  pitcher_name,
  pitchSpeed         AS max_pitch_speed
FROM ranked
WHERE rn = 1
ORDER BY team_name;