--  Pitcher with the highest (non‑zero) pitch speed for every club,
--  considering both regular‑season and post‑season games.

WITH union_events AS (
  -- Regular season
  SELECT
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    pitchSpeed,
    -- figure out which club the pitcher was actually pitching for
    CASE
      WHEN pitcherId IN (homeFielder1 ,homeFielder2 ,homeFielder3 ,homeFielder4 ,
                         homeFielder5 ,homeFielder6 ,homeFielder7 ,homeFielder8 ,
                         homeFielder9 ,homeFielder10,homeFielder11,homeFielder12) THEN homeTeamId
      WHEN pitcherId IN (awayFielder1 ,awayFielder2 ,awayFielder3 ,awayFielder4 ,
                         awayFielder5 ,awayFielder6 ,awayFielder7 ,awayFielder8 ,
                         awayFielder9 ,awayFielder10,awayFielder11,awayFielder12) THEN awayTeamId
    END                                              AS teamId,
    CASE
      WHEN pitcherId IN (homeFielder1 ,homeFielder2 ,homeFielder3 ,homeFielder4 ,
                         homeFielder5 ,homeFielder6 ,homeFielder7 ,homeFielder8 ,
                         homeFielder9 ,homeFielder10,homeFielder11,homeFielder12) THEN homeTeamName
      WHEN pitcherId IN (awayFielder1 ,awayFielder2 ,awayFielder3 ,awayFielder4 ,
                         awayFielder5 ,awayFielder6 ,awayFielder7 ,awayFielder8 ,
                         awayFielder9 ,awayFielder10,awayFielder11,awayFielder12) THEN awayTeamName
    END                                              AS teamName
  FROM `bigquery-public-data.baseball.games_wide`
  WHERE pitchSpeed > 0

  UNION ALL

  -- Post‑season
  SELECT
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    pitchSpeed,
    CASE
      WHEN pitcherId IN (homeFielder1 ,homeFielder2 ,homeFielder3 ,homeFielder4 ,
                         homeFielder5 ,homeFielder6 ,homeFielder7 ,homeFielder8 ,
                         homeFielder9 ,homeFielder10,homeFielder11,homeFielder12) THEN homeTeamId
      WHEN pitcherId IN (awayFielder1 ,awayFielder2 ,awayFielder3 ,awayFielder4 ,
                         awayFielder5 ,awayFielder6 ,awayFielder7 ,awayFielder8 ,
                         awayFielder9 ,awayFielder10,awayFielder11,awayFielder12) THEN awayTeamId
    END                                              AS teamId,
    CASE
      WHEN pitcherId IN (homeFielder1 ,homeFielder2 ,homeFielder3 ,homeFielder4 ,
                         homeFielder5 ,homeFielder6 ,homeFielder7 ,homeFielder8 ,
                         homeFielder9 ,homeFielder10,homeFielder11,homeFielder12) THEN homeTeamName
      WHEN pitcherId IN (awayFielder1 ,awayFielder2 ,awayFielder3 ,awayFielder4 ,
                         awayFielder5 ,awayFielder6 ,awayFielder7 ,awayFielder8 ,
                         awayFielder9 ,awayFielder10,awayFielder11,awayFielder12) THEN awayTeamName
    END                                              AS teamName
  FROM `bigquery-public-data.baseball.games_post_wide`
  WHERE pitchSpeed > 0
),

filtered AS (
  -- keep only rows where we could positively link the pitcher to a club
  SELECT *
  FROM union_events
  WHERE teamId IS NOT NULL
),

max_speed_per_team AS (
  SELECT
    teamId,
    MAX(pitchSpeed) AS maxSpeed
  FROM filtered
  GROUP BY teamId
),

best_pitchers AS (
  -- may be more than one pitcher tied for top speed; choose one arbitrarily
  SELECT
    f.teamId,
    ANY_VALUE(f.teamName)          AS teamName,
    ANY_VALUE(f.pitcherId)         AS pitcherId,
    ANY_VALUE(f.pitcherFirstName)  AS firstName,
    ANY_VALUE(f.pitcherLastName)   AS lastName,
    m.maxSpeed
  FROM filtered f
  JOIN max_speed_per_team m
    ON  f.teamId     = m.teamId
    AND f.pitchSpeed = m.maxSpeed
  GROUP BY
    f.teamId,
    m.maxSpeed
)

SELECT
  teamName,
  CONCAT(firstName, ' ', lastName) AS pitcherFullName,
  maxSpeed                         AS maxPitchSpeed
FROM best_pitchers
ORDER BY teamName;