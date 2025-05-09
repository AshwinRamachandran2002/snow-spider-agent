-- Fastest recorded pitch for every franchise (regular-season + post-season)
WITH all_pitches AS (
  SELECT * FROM `bigquery-public-data.baseball.games_wide`
  UNION ALL
  SELECT * FROM `bigquery-public-data.baseball.games_post_wide`
),
tagged AS (
  SELECT
    -- identify which team the pitcher was throwing for in this play
    CASE
      WHEN pitchSpeed > 0
           AND pitcherId IN (homeFielder1, homeFielder10) THEN homeTeamId
      WHEN pitchSpeed > 0
           AND pitcherId IN (awayFielder1, awayFielder10) THEN awayTeamId
      ELSE NULL
    END                           AS team_id,
    pitcherId,
    pitcherFirstName              AS first_name,
    pitcherLastName               AS last_name,
    pitchSpeed
  FROM all_pitches
  WHERE pitchSpeed > 0            -- ignore non-pitches / bad data
),
per_pitcher AS (                  -- best speed each pitcher achieved for that team
  SELECT
    team_id,
    pitcherId,
    ANY_VALUE(first_name)  AS first_name,
    ANY_VALUE(last_name)   AS last_name,
    MAX(pitchSpeed)        AS max_speed
  FROM tagged
  WHERE team_id IS NOT NULL       -- keep only validated team assignments
  GROUP BY team_id, pitcherId
),
ranked AS (                       -- rank pitchers inside each franchise
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY team_id ORDER BY max_speed DESC) AS rn
  FROM per_pitcher
)
SELECT
  team_id,
  CONCAT(first_name, ' ', last_name) AS pitcher_name,
  max_speed AS fastest_pitch
FROM ranked
WHERE rn = 1                       -- one row per franchise
ORDER BY fastest_pitch DESC;