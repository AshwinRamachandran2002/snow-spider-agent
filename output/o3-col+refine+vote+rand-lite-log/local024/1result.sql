WITH player_match_runs AS (
    /* runs scored by each player in every match */
    SELECT
        b."striker"      AS "player_id",
        b."match_id",
        SUM(bs."runs_scored") AS "runs_in_match"
    FROM "ball_by_ball"   b
    JOIN "batsman_scored" bs
      ON b."match_id"   = bs."match_id"
     AND b."over_id"    = bs."over_id"
     AND b."ball_id"    = bs."ball_id"
     AND b."innings_no" = bs."innings_no"
    GROUP BY b."striker", b."match_id"
),
player_avg AS (
    /* average runs per match for every player */
    SELECT
        "player_id",
        AVG("runs_in_match") AS "avg_runs_per_match"
    FROM player_match_runs
    GROUP BY "player_id"
),
country_avg AS (
    /* average of those player-averages for each country */
    SELECT
        p."country_name",
        AVG(pa."avg_runs_per_match") AS "country_batting_avg"
    FROM player_avg pa
    JOIN "player" p
      ON p."player_id" = pa."player_id"
    GROUP BY p."country_name"
)
SELECT
    "country_name",
    ROUND("country_batting_avg", 4) AS "country_batting_avg"
FROM country_avg
ORDER BY "country_batting_avg" DESC
LIMIT 5;