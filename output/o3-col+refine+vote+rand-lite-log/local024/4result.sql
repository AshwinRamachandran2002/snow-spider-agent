WITH player_runs AS (
    SELECT  b."striker"                        AS "player_id",
            SUM(s."runs_scored")              AS "total_runs"
    FROM    "ball_by_ball"   AS b
    JOIN    "batsman_scored" AS s
           ON b."match_id" = s."match_id"
          AND b."over_id"  = s."over_id"
          AND b."ball_id"  = s."ball_id"
    GROUP BY b."striker"
),
player_matches AS (
    SELECT  "player_id",
            COUNT(DISTINCT "match_id")        AS "matches_played"
    FROM    "player_match"
    GROUP BY "player_id"
),
player_averages AS (
    SELECT  pr."player_id",
            1.0 * pr."total_runs" / pm."matches_played"  AS "avg_runs_per_match"
    FROM    player_runs    AS pr
    JOIN    player_matches AS pm
           ON pr."player_id" = pm."player_id"
),
country_averages AS (
    SELECT  p."country_name",
            AVG(pa."avg_runs_per_match")      AS "country_batting_avg"
    FROM    player_averages AS pa
    JOIN    "player"        AS p
           ON pa."player_id" = p."player_id"
    GROUP BY p."country_name"
)
SELECT  "country_name",
        ROUND("country_batting_avg", 4)       AS "country_batting_avg"
FROM    country_averages
ORDER BY "country_batting_avg" DESC
LIMIT 5;