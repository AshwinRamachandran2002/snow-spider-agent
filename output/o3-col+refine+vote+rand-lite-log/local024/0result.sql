WITH player_stats AS (
    /* total runs and matches played by each player */
    SELECT 
        b."striker"                         AS player_id,
        SUM(bs."runs_scored")               AS total_runs,
        COUNT(DISTINCT b."match_id")        AS matches_played
    FROM "ball_by_ball"   AS b
    JOIN "batsman_scored" AS bs
      ON b."match_id"   = bs."match_id"
     AND b."over_id"    = bs."over_id"
     AND b."ball_id"    = bs."ball_id"
     AND b."innings_no" = bs."innings_no"
    GROUP BY b."striker"
),
player_avg AS (
    /* individual average runs per match */
    SELECT
        player_id,
        1.0 * total_runs / matches_played   AS avg_runs_per_match
    FROM player_stats
),
country_avg AS (
    /* country-level average of players' averages */
    SELECT
        p."country_name",
        AVG(pa."avg_runs_per_match")        AS country_batting_average
    FROM player_avg AS pa
    JOIN "player" AS p
      ON pa.player_id = p."player_id"
    GROUP BY p."country_name"
)
SELECT
    "country_name",
    ROUND(country_batting_average, 4)       AS country_batting_average
FROM country_avg
ORDER BY country_batting_average DESC
LIMIT 5;