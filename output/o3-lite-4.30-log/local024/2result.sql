WITH player_runs AS (
    SELECT
        bb."striker"          AS player_id,
        bs."match_id",
        SUM(bs."runs_scored") AS runs_in_match
    FROM "batsman_scored" AS bs
    JOIN "ball_by_ball"   AS bb
      ON bb."match_id"   = bs."match_id"
     AND bb."over_id"    = bs."over_id"
     AND bb."ball_id"    = bs."ball_id"
     AND bb."innings_no" = bs."innings_no"
    GROUP BY bb."striker", bs."match_id"
),
player_avg AS (
    SELECT
        player_id,
        AVG(runs_in_match) AS avg_runs_per_match
    FROM player_runs
    GROUP BY player_id
),
country_avg AS (
    SELECT
        p."country_name"                   AS country,
        AVG(pa.avg_runs_per_match)         AS average_player_runs_per_match
    FROM player_avg AS pa
    JOIN "player"  AS p
      ON p."player_id" = pa."player_id"
    GROUP BY p."country_name"
)
SELECT
    country,
    ROUND(average_player_runs_per_match, 4) AS average_player_runs_per_match
FROM country_avg
ORDER BY average_player_runs_per_match DESC, country ASC
LIMIT 5;