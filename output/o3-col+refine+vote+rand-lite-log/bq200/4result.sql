/*  Fastest recorded pitch for every club (regular-season + post-season)
    ------------------------------------------------------------------
    1.  Bring together every pitch that has a non-zero velocity from both
        `games_wide` (regular) and `games_post_wide` (post-season).
        For each row decide which club the pitcher belongs to by checking
        whether the pitcherId appears in the home- or away-fielder lists.

    2.  For every (team × pitcher) pair, keep the highest speed we ever
        see that pitcher throw for that club.

    3.  For each club pick the single pitcher whose recorded top speed is
        the greatest; attach the pitcher’s name and return the result.
*/

WITH all_pitches AS (
  SELECT
    pitchSpeed,
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    CASE
      WHEN pitcherId IN (homeFielder1,homeFielder2,homeFielder3,homeFielder4,
                         homeFielder5,homeFielder6,homeFielder7,homeFielder8,
                         homeFielder9,homeFielder10,homeFielder11,homeFielder12)
           THEN homeTeamId
      WHEN pitcherId IN (awayFielder1,awayFielder2,awayFielder3,awayFielder4,
                         awayFielder5,awayFielder6,awayFielder7,awayFielder8,
                         awayFielder9,awayFielder10,awayFielder11,awayFielder12)
           THEN awayTeamId
    END AS teamId
  FROM `bigquery-public-data.baseball.games_wide`
  WHERE pitchSpeed > 0

  UNION ALL

  SELECT
    pitchSpeed,
    pitcherId,
    pitcherFirstName,
    pitcherLastName,
    CASE
      WHEN pitcherId IN (homeFielder1,homeFielder2,homeFielder3,homeFielder4,
                         homeFielder5,homeFielder6,homeFielder7,homeFielder8,
                         homeFielder9,homeFielder10,homeFielder11,homeFielder12)
           THEN homeTeamId
      WHEN pitcherId IN (awayFielder1,awayFielder2,awayFielder3,awayFielder4,
                         awayFielder5,awayFielder6,awayFielder7,awayFielder8,
                         awayFielder9,awayFielder10,awayFielder11,awayFielder12)
           THEN awayTeamId
    END AS teamId
  FROM `bigquery-public-data.baseball.games_post_wide`
  WHERE pitchSpeed > 0
),

/*  Max velocity for every (team, pitcher) combo */
max_by_pitcher AS (
  SELECT
    teamId,
    pitcherId,
    MAX(pitchSpeed) AS max_speed
  FROM all_pitches
  WHERE teamId IS NOT NULL
  GROUP BY teamId, pitcherId
),

/*  One fastest pitcher per club */
team_fastest AS (
  SELECT
    teamId,
    ARRAY_AGG(STRUCT(pitcherId, max_speed)
              ORDER BY max_speed DESC, pitcherId         -- tie-break by id
              LIMIT 1)[OFFSET(0)] AS best_pitcher
  FROM max_by_pitcher
  GROUP BY teamId
)

/*  Final output with pitcher’s full name */
SELECT
  tf.teamId,
  CONCAT(pp.pitcherFirstName, ' ', pp.pitcherLastName) AS pitcher_fullName,
  tf.best_pitcher.max_speed                           AS fastest_pitchSpeed
FROM team_fastest AS tf
LEFT JOIN (
  SELECT DISTINCT pitcherId, pitcherFirstName, pitcherLastName
  FROM all_pitches
) AS pp
ON pp.pitcherId = tf.best_pitcher.pitcherId
ORDER BY fastest_pitchSpeed DESC;