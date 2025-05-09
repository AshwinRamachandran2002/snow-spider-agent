/*  Highest recorded pitch speed ( > 0 ) for every team across
    regular-season (`games_wide`) and post-season (`games_post_wide`) data.

   Steps
   1.  Union REG + POST rows that have a non-zero pitchSpeed.
   2.  Build arrays of the 12 listed home/away fielders for each row.
   3.  Keep only those rows where the pitcher’s ID actually appears in
       the corresponding home or away fielder list and tag the row with
       the correct teamId (the team the pitcher is throwing for).
   4.  For each (team, pitcher) pair compute the maximum pitchSpeed.
   5.  For each team keep the pitcher who owns the single highest
       speed; if several pitchers tie, the one returned is arbitrary.
*/
WITH reg_post AS (          -- 1. REG + POST with pitch data
    SELECT
        gameId,
        homeTeamId,
        awayTeamId,
        pitcherId,
        CONCAT(pitcherFirstName,' ',pitcherLastName) AS pitcherName,
        pitchSpeed,
        ARRAY[homeFielder1,homeFielder2,homeFielder3,homeFielder4,homeFielder5,
              homeFielder6,homeFielder7,homeFielder8,homeFielder9,homeFielder10,
              homeFielder11,homeFielder12]            AS home_list,
        ARRAY[awayFielder1,awayFielder2,awayFielder3,awayFielder4,awayFielder5,
              awayFielder6,awayFielder7,awayFielder8,awayFielder9,awayFielder10,
              awayFielder11,awayFielder12]            AS away_list
    FROM   `bigquery-public-data.baseball.games_wide`
    WHERE  pitchSpeed > 0

    UNION ALL

    SELECT
        gameId,
        homeTeamId,
        awayTeamId,
        pitcherId,
        CONCAT(pitcherFirstName,' ',pitcherLastName) AS pitcherName,
        pitchSpeed,
        ARRAY[homeFielder1,homeFielder2,homeFielder3,homeFielder4,homeFielder5,
              homeFielder6,homeFielder7,homeFielder8,homeFielder9,homeFielder10,
              homeFielder11,homeFielder12],
        ARRAY[awayFielder1,awayFielder2,awayFielder3,awayFielder4,awayFielder5,
              awayFielder6,awayFielder7,awayFielder8,awayFielder9,awayFielder10,
              awayFielder11,awayFielder12]
    FROM   `bigquery-public-data.baseball.games_post_wide`
    WHERE  pitchSpeed > 0
),

tagged AS (                 -- 2-3. keep rows where pitcher is in fielder list
    SELECT
        CASE
            WHEN pitcherId IN UNNEST(home_list) THEN homeTeamId
            WHEN pitcherId IN UNNEST(away_list) THEN awayTeamId
        END                                                  AS teamId,
        pitcherId,
        pitcherName,
        pitchSpeed
    FROM   reg_post
    WHERE  pitcherId IN UNNEST(home_list)
        OR pitcherId IN UNNEST(away_list)
),

per_pitcher AS (            -- 4. max speed per (team, pitcher)
    SELECT
        teamId,
        pitcherId,
        pitcherName,
        MAX(pitchSpeed) AS max_pitch_speed
    FROM   tagged
    GROUP  BY teamId, pitcherId, pitcherName
)

-- 5. one (team) row – the pitcher with the highest recorded speed
SELECT
    teamId,
    pitcherId,
    pitcherName,
    max_pitch_speed
FROM   per_pitcher
QUALIFY ROW_NUMBER() OVER (PARTITION BY teamId ORDER BY max_pitch_speed DESC) = 1
ORDER  BY teamId;