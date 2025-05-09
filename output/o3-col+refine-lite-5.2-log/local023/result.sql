WITH runs_per_match AS (
    /* runs scored by each batsman in every individual match of season 5 */
    SELECT 
        bbb."match_id",
        bbb."striker"                  AS "player_id",
        SUM(bs."runs_scored")          AS "runs_in_match"
    FROM "ball_by_ball"  AS bbb
    JOIN "batsman_scored" AS bs
         ON bs."match_id"   = bbb."match_id"
        AND bs."over_id"    = bbb."over_id"
        AND bs."ball_id"    = bbb."ball_id"
        AND bs."innings_no" = bbb."innings_no"
    JOIN "match" AS m
         ON m."match_id" = bbb."match_id"
    WHERE m."season_id" = 5
    GROUP BY bbb."match_id", bbb."striker"
),
total_runs AS (
    /* total runs across all season‑5 matches for each player */
    SELECT 
        "player_id",
        SUM("runs_in_match") AS "total_runs"
    FROM runs_per_match
    GROUP BY "player_id"
),
matches_played AS (
    /* number of season‑5 matches each player appeared in */
    SELECT 
        pm."player_id",
        COUNT(DISTINCT pm."match_id") AS "matches_played"
    FROM "player_match" AS pm
    JOIN "match" AS m
         ON m."match_id" = pm."match_id"
    WHERE m."season_id" = 5
    GROUP BY pm."player_id"
),
avg_runs AS (
    /* batting average (runs per match) for each player in season 5 */
    SELECT
        tr."player_id",
        tr."total_runs" * 1.0 / mp."matches_played" AS "avg_runs"
    FROM total_runs      AS tr
    JOIN matches_played  AS mp
         ON mp."player_id" = tr."player_id"
)
SELECT 
    p."player_name",
    ROUND(ar."avg_runs", 4) AS "batting_average"
FROM avg_runs AS ar
JOIN "player" AS p
     ON p."player_id" = ar."player_id"
ORDER BY ar."avg_runs" DESC, p."player_name" ASC
LIMIT 5;