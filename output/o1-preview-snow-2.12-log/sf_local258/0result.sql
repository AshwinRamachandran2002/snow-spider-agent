WITH bowler_stats AS (
    SELECT 
        b."bowler", 
        COUNT(w."player_out") AS "total_wickets",
        SUM(s."runs_scored") AS "total_runs_conceded",
        COUNT(*) AS "total_balls"
    FROM "IPL"."IPL"."BALL_BY_BALL" b
    LEFT JOIN "IPL"."IPL"."WICKET_TAKEN" w
        ON b."match_id" = w."match_id"
        AND b."over_id" = w."over_id"
        AND b."ball_id" = w."ball_id"
        AND b."innings_no" = w."innings_no"
    JOIN "IPL"."IPL"."BATSMAN_SCORED" s
        ON b."match_id" = s."match_id"
        AND b."over_id" = s."over_id"
        AND b."ball_id" = s."ball_id"
        AND b."innings_no" = s."innings_no"
    GROUP BY b."bowler"
),
best_performance AS (
    SELECT
        b."bowler",
        b."match_id",
        COUNT(w."player_out") AS "wickets_in_match",
        SUM(s."runs_scored") AS "runs_conceded_in_match"
    FROM "IPL"."IPL"."BALL_BY_BALL" b
    LEFT JOIN "IPL"."IPL"."WICKET_TAKEN" w
        ON b."match_id" = w."match_id"
        AND b."over_id" = w."over_id"
        AND b."ball_id" = w."ball_id"
        AND b."innings_no" = w."innings_no"
    JOIN "IPL"."IPL"."BATSMAN_SCORED" s
        ON b."match_id" = s."match_id"
        AND b."over_id" = s."over_id"
        AND b."ball_id" = s."ball_id"
        AND b."innings_no" = s."innings_no"
    GROUP BY b."bowler", b."match_id"
),
best_performance_per_bowler AS (
    SELECT
        bp."bowler",
        bp."wickets_in_match",
        bp."runs_conceded_in_match",
        ROW_NUMBER() OVER (PARTITION BY bp."bowler" 
                           ORDER BY bp."wickets_in_match" DESC, bp."runs_conceded_in_match" ASC) AS rn
    FROM best_performance bp
)
SELECT
    p."player_name" AS "bowler_name",
    bs."total_wickets",
    ROUND((bs."total_runs_conceded" / (bs."total_balls" / 6)), 4) AS "economy_rate",
    ROUND(CASE WHEN bs."total_wickets" > 0 THEN (bs."total_balls" / bs."total_wickets") ELSE NULL END, 4) AS "strike_rate",
    CONCAT(bppb."wickets_in_match", '-', bppb."runs_conceded_in_match") AS "best_performance"
FROM bowler_stats bs
JOIN "IPL"."IPL"."PLAYER" p ON bs."bowler" = p."player_id"
LEFT JOIN best_performance_per_bowler bppb ON bs."bowler" = bppb."bowler" AND bppb.rn = 1
ORDER BY bs."total_wickets" DESC NULLS LAST