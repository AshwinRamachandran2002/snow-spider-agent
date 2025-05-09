/*  For every MLB team (regular‐ AND post-season combined), find
    the fastest valid pitch thrown and the pitcher who threw it.
    A pitch is attributed to a team only when that pitcher’s ID
    appears among that game’s home- or away-fielder lists.        */

WITH all_games AS (
  -- Combine regular-season and post-season play-by-play tables
  SELECT * FROM `bigquery-public-data.baseball.games_wide`
  UNION ALL
  SELECT * FROM `bigquery-public-data.baseball.games_post_wide`
),

pitch_with_team AS (
  /*  Keep only pitches with a positive speed and derive the team
      the pitcher is playing for in that game by checking whether
      their ID is present in the home- or away-fielder arrays.     */
  SELECT
    CASE
      WHEN pitcherId IN UNNEST([
        homeFielder1,homeFielder2,homeFielder3,homeFielder4,
        homeFielder5,homeFielder6,homeFielder7,homeFielder8,
        homeFielder9,homeFielder10,homeFielder11,homeFielder12
      ]) THEN homeTeamId
      WHEN pitcherId IN UNNEST([
        awayFielder1,awayFielder2,awayFielder3,awayFielder4,
        awayFielder5,awayFielder6,awayFielder7,awayFielder8,
        awayFielder9,awayFielder10,awayFielder11,awayFielder12
      ]) THEN awayTeamId
    END AS teamId,
    pitcherId,
    CONCAT(pitcherFirstName,' ',pitcherLastName) AS pitcher_name,
    pitchSpeed
  FROM all_games
  WHERE pitchSpeed > 0
),

max_speed_per_pitcher AS (
  /*  Each (team, pitcher) pair → their personal top pitch speed. */
  SELECT
    teamId,
    pitcherId,
    ANY_VALUE(pitcher_name) AS pitcher_name,
    MAX(pitchSpeed)        AS max_speed
  FROM pitch_with_team
  WHERE teamId IS NOT NULL       -- drop ambiguous rows
  GROUP BY teamId, pitcherId
),

fastest_per_team AS (
  /*  Rank pitchers within each team by their max speed and keep
      only the single fastest one per team.                       */
  SELECT
    teamId,
    pitcherId,
    pitcher_name,
    max_speed,
    ROW_NUMBER() OVER (PARTITION BY teamId
                       ORDER BY max_speed DESC) AS rn
  FROM max_speed_per_pitcher
)

SELECT
  teamId                              AS team_id,
  pitcher_name                        AS fastest_pitcher,
  max_speed                           AS fastest_non_zero_pitch_speed
FROM fastest_per_team
WHERE rn = 1
ORDER BY team_id;