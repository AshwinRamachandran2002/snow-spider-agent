/* Highest non‑zero pitch speed for every MLB team (regular + post‑season) */
WITH all_pitches AS (
  SELECT
    -- deduce the team the pitcher is playing for in this event
    CASE
      WHEN pitcherId IN (homeFielder1,homeFielder2,homeFielder3,homeFielder4,
                         homeFielder5,homeFielder6,homeFielder7,homeFielder8,
                         homeFielder9,homeFielder10,homeFielder11,homeFielder12)
           THEN homeTeamId
      WHEN pitcherId IN (awayFielder1,awayFielder2,awayFielder3,awayFielder4,
                         awayFielder5,awayFielder6,awayFielder7,awayFielder8,
                         awayFielder9,awayFielder10,awayFielder11,awayFielder12)
           THEN awayTeamId
    END                                                            AS team_id,
    CASE
      WHEN pitcherId IN (homeFielder1,homeFielder2,homeFielder3,homeFielder4,
                         homeFielder5,homeFielder6,homeFielder7,homeFielder8,
                         homeFielder9,homeFielder10,homeFielder11,homeFielder12)
           THEN homeTeamName
      WHEN pitcherId IN (awayFielder1,awayFielder2,awayFielder3,awayFielder4,
                         awayFielder5,awayFielder6,awayFielder7,awayFielder8,
                         awayFielder9,awayFielder10,awayFielder11,awayFielder12)
           THEN awayTeamName
    END                                                            AS team_name,
    CONCAT(pitcherFirstName,' ',pitcherLastName)                   AS pitcher_name,
    pitchSpeed                                                     AS pitch_speed
  FROM (
        SELECT * FROM `bigquery-public-data.baseball.games_wide`
        UNION ALL
        SELECT * FROM `bigquery-public-data.baseball.games_post_wide`
       )
  WHERE pitchSpeed > 0                                   -- non‑zero speeds only
),
valid_pitches AS (
  SELECT *
  FROM   all_pitches
  WHERE  team_id IS NOT NULL                             -- keep rows with confirmed team
),
ranked AS (                                              -- rank pitches inside each team
  SELECT
    team_name,
    pitcher_name,
    pitch_speed,
    ROW_NUMBER() OVER (PARTITION BY team_name
                       ORDER BY pitch_speed DESC, pitcher_name) AS rn
  FROM valid_pitches
)

SELECT
  team_name                                                  AS team,
  MAX(CASE WHEN rn = 1 THEN pitcher_name END)                AS pitcher_name,
  ROUND(MAX(pitch_speed),4)                                  AS max_pitch_speed_mph
FROM ranked
GROUP BY team_name
ORDER BY max_pitch_speed_mph DESC, team;