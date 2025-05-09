WITH player_match_runs AS (
    -- runs scored by each batsman in every match
    SELECT  bbb."striker"  AS "player_id",
            bbb."match_id",
            SUM(bs."runs_scored") AS "runs_in_match"
    FROM    "ball_by_ball"  AS bbb
    JOIN    "batsman_scored" AS bs
           ON bbb."match_id" = bs."match_id"
          AND bbb."over_id"  = bs."over_id"
          AND bbb."ball_id"  = bs."ball_id"
    GROUP BY bbb."striker", bbb."match_id"
),
player_average AS (
    -- average runs per match for every player
    SELECT  "player_id",
            AVG("runs_in_match") AS "avg_runs_per_match"
    FROM    player_match_runs
    GROUP BY "player_id"
)
SELECT   p."country_name",
         ROUND(AVG(pa."avg_runs_per_match"), 4) AS "country_batting_average"
FROM     player_average pa
JOIN     "player" p
       ON pa."player_id" = p."player_id"
GROUP BY p."country_name"
ORDER BY "country_batting_average" DESC
LIMIT 5;