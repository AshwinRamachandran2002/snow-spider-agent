/*  Fastest valid pitch ( > 0 mph ) recorded for every club
    — regular-season and post-season combined                          */

WITH all_pitches AS (           -- union both wide tables, keep only real pitches
  SELECT
    pitchSpeed,
    pitcherId,
    homeTeamId,
    awayTeamId,
    [homeFielder1,homeFielder2,homeFielder3,homeFielder4,
     homeFielder5,homeFielder6,homeFielder7,homeFielder8,
     homeFielder9,homeFielder10,homeFielder11,homeFielder12] AS home_ids,
    [awayFielder1,awayFielder2,awayFielder3,awayFielder4,
     awayFielder5,awayFielder6,awayFielder7,awayFielder8,
     awayFielder9,awayFielder10,awayFielder11,awayFielder12] AS away_ids
  FROM `bigquery-public-data.baseball.games_wide`
  WHERE pitchSpeed > 0

  UNION ALL

  SELECT
    pitchSpeed,
    pitcherId,
    homeTeamId,
    awayTeamId,
    [homeFielder1,homeFielder2,homeFielder3,homeFielder4,
     homeFielder5,homeFielder6,homeFielder7,homeFielder8,
     homeFielder9,homeFielder10,homeFielder11,homeFielder12],
    [awayFielder1,awayFielder2,awayFielder3,awayFielder4,
     awayFielder5,awayFielder6,awayFielder7,awayFielder8,
     awayFielder9,awayFielder10,awayFielder11,awayFielder12]
  FROM `bigquery-public-data.baseball.games_post_wide`
  WHERE pitchSpeed > 0
),

team_pitches AS (               -- keep only rows where pitcher really belongs to that club
  SELECT
    pitchSpeed,
    pitcherId,
    CASE
      WHEN pitcherId IN UNNEST(home_ids) THEN homeTeamId
      WHEN pitcherId IN UNNEST(away_ids) THEN awayTeamId
    END AS team_id
  FROM all_pitches
  WHERE pitcherId IN UNNEST(home_ids)
     OR pitcherId IN UNNEST(away_ids)
),

per_pitcher AS (                -- each pitcher’s personal top speed for the club
  SELECT
    team_id,
    pitcherId,
    MAX(pitchSpeed) AS max_speed
  FROM team_pitches
  GROUP BY team_id, pitcherId
),

team_best AS (                  -- club record
  SELECT
    team_id,
    MAX(max_speed) AS top_speed
  FROM per_pitcher
  GROUP BY team_id
),

top_pitchers AS (               -- pitcher(s) whose speed equals club record (ties kept)
  SELECT p.*
  FROM per_pitcher p
  JOIN team_best t
    ON p.team_id = t.team_id
   AND p.max_speed = t.top_speed
),

names AS (                      -- unique id → full name mapping from both tables
  SELECT DISTINCT
    pitcherId,
    CONCAT(pitcherFirstName,' ',pitcherLastName) AS full_name
  FROM `bigquery-public-data.baseball.games_wide`
  UNION DISTINCT
  SELECT DISTINCT
    pitcherId,
    CONCAT(pitcherFirstName,' ',pitcherLastName)
  FROM `bigquery-public-data.baseball.games_post_wide`
)

SELECT
  tp.team_id,
  n.full_name,
  tp.max_speed
FROM top_pitchers tp
LEFT JOIN names n USING (pitcherId)
ORDER BY tp.team_id, n.full_name;