-- Pitcher with the highest (non‑zero) recorded pitch speed for every team
WITH all_pitches AS (
  -- Regular season ---------------------------------------------------------
  SELECT
    g.pitcherId,
    g.pitcherFirstName,
    g.pitcherLastName,
    g.pitchSpeed,
    -- identify the team the pitcher belonged to in this game
    CASE
      WHEN EXISTS (SELECT 1
                   FROM UNNEST([g.homeFielder1,g.homeFielder2,g.homeFielder3,g.homeFielder4,
                                g.homeFielder5,g.homeFielder6,g.homeFielder7,g.homeFielder8,
                                g.homeFielder9,g.homeFielder10,g.homeFielder11,g.homeFielder12]) f
                   WHERE f = g.pitcherId) THEN g.homeTeamId
      WHEN EXISTS (SELECT 1
                   FROM UNNEST([g.awayFielder1,g.awayFielder2,g.awayFielder3,g.awayFielder4,
                                g.awayFielder5,g.awayFielder6,g.awayFielder7,g.awayFielder8,
                                g.awayFielder9,g.awayFielder10,g.awayFielder11,g.awayFielder12]) f
                   WHERE f = g.pitcherId) THEN g.awayTeamId
    END                                                   AS teamId
  FROM `bigquery-public-data.baseball.games_wide` g
  WHERE g.pitchSpeed > 0

  UNION ALL

  -- Post‑season ------------------------------------------------------------
  SELECT
    g.pitcherId,
    g.pitcherFirstName,
    g.pitcherLastName,
    g.pitchSpeed,
    CASE
      WHEN EXISTS (SELECT 1
                   FROM UNNEST([g.homeFielder1,g.homeFielder2,g.homeFielder3,g.homeFielder4,
                                g.homeFielder5,g.homeFielder6,g.homeFielder7,g.homeFielder8,
                                g.homeFielder9,g.homeFielder10,g.homeFielder11,g.homeFielder12]) f
                   WHERE f = g.pitcherId) THEN g.homeTeamId
      WHEN EXISTS (SELECT 1
                   FROM UNNEST([g.awayFielder1,g.awayFielder2,g.awayFielder3,g.awayFielder4,
                                g.awayFielder5,g.awayFielder6,g.awayFielder7,g.awayFielder8,
                                g.awayFielder9,g.awayFielder10,g.awayFielder11,g.awayFielder12]) f
                   WHERE f = g.pitcherId) THEN g.awayTeamId
    END                                                   AS teamId
  FROM `bigquery-public-data.baseball.games_post_wide` g
  WHERE g.pitchSpeed > 0
),
valid_pitches AS (
  SELECT *
  FROM   all_pitches
  WHERE  teamId IS NOT NULL           -- pitcher confirmed on the team’s fielding list
),
per_pitcher_team AS (                 -- best speed each pitcher registered for every team
  SELECT
    teamId,
    pitcherId,
    ANY_VALUE(pitcherFirstName) AS pitcherFirstName,
    ANY_VALUE(pitcherLastName)  AS pitcherLastName,
    MAX(pitchSpeed)             AS max_pitch_speed
  FROM valid_pitches
  GROUP BY teamId, pitcherId
),
team_best AS (                        -- take the single fastest pitcher per team
  SELECT
    teamId,
    ARRAY_AGG(
      STRUCT(pitcherId, pitcherFirstName, pitcherLastName, max_pitch_speed)
      ORDER BY max_pitch_speed DESC, pitcherId            -- tie‑breaker on id
      LIMIT 1
    )[OFFSET(0)] AS best_pitcher
  FROM per_pitcher_team
  GROUP BY teamId
)
SELECT
  teamId,
  best_pitcher.pitcherId                                   AS pitcherId,
  CONCAT(best_pitcher.pitcherFirstName,' ',best_pitcher.pitcherLastName)
                                                          AS pitcherFullName,
  best_pitcher.max_pitch_speed                            AS maxPitchSpeed
FROM team_best
ORDER BY maxPitchSpeed DESC;