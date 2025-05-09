WITH bowler_stats AS (
    SELECT
        b."bowler",
        SUM(bs."runs_scored") AS "total_runs_conceded",
        COUNT(*) AS "balls_bowled",
        SUM(CASE WHEN w."kind_out" IS NOT NULL THEN 1 ELSE 0 END) AS "total_wickets"
    FROM IPL.IPL."BALL_BY_BALL" b
    LEFT JOIN IPL.IPL."BATSMAN_SCORED" bs ON b."match_id" = bs."match_id"
        AND b."innings_no" = bs."innings_no"
        AND b."over_id" = bs."over_id"
        AND b."ball_id" = bs."ball_id"
    LEFT JOIN (
        SELECT "match_id", "innings_no", "over_id", "ball_id", "kind_out"
        FROM IPL.IPL."WICKET_TAKEN"
        WHERE "kind_out" IN ('bowled', 'caught', 'caught and bowled', 'lbw', 'stumped', 'hit wicket')
    ) w ON b."match_id" = w."match_id"
        AND b."innings_no" = w."innings_no"
        AND b."over_id" = w."over_id"
        AND b."ball_id" = w."ball_id"
    GROUP BY b."bowler"
),
best_match_performance AS (
    SELECT
        s."bowler",
        s."wickets_taken",
        s."runs_conceded",
        ROW_NUMBER() OVER (PARTITION BY s."bowler"
            ORDER BY s."wickets_taken" DESC, s."runs_conceded" ASC) AS rn
    FROM (
        SELECT
            b."bowler",
            b."match_id",
            SUM(bs."runs_scored") AS "runs_conceded",
            SUM(CASE WHEN w."kind_out" IS NOT NULL THEN 1 ELSE 0 END) AS "wickets_taken"
        FROM IPL.IPL."BALL_BY_BALL" b
        LEFT JOIN IPL.IPL."BATSMAN_SCORED" bs ON b."match_id" = bs."match_id"
            AND b."innings_no" = bs."innings_no"
            AND b."over_id" = bs."over_id"
            AND b."ball_id" = bs."ball_id"
        LEFT JOIN (
            SELECT "match_id", "innings_no", "over_id", "ball_id", "kind_out"
            FROM IPL.IPL."WICKET_TAKEN"
            WHERE "kind_out" IN ('bowled', 'caught', 'caught and bowled', 'lbw', 'stumped', 'hit wicket')
        ) w ON b."match_id" = w."match_id"
            AND b."innings_no" = w."innings_no"
            AND b."over_id" = w."over_id"
            AND b."ball_id" = w."ball_id"
        GROUP BY b."bowler", b."match_id"
    ) s
    WHERE s."wickets_taken" > 0
)
SELECT
    p."player_name" AS "bowler_name",
    bs."total_wickets",
    ROUND(bs."total_runs_conceded" / (bs."balls_bowled" / 6.0), 4) AS "economy_rate",
    ROUND(bs."balls_bowled" / NULLIF(bs."total_wickets", 0), 4) AS "strike_rate",
    CONCAT(bmp."wickets_taken", '-', bmp."runs_conceded") AS "best_performance"
FROM bowler_stats bs
JOIN IPL.IPL."PLAYER" p ON bs."bowler" = p."player_id"
LEFT JOIN (
    SELECT "bowler", "wickets_taken", "runs_conceded"
    FROM best_match_performance
    WHERE rn = 1
) bmp ON bs."bowler" = bmp."bowler"
ORDER BY bs."total_wickets" DESC NULLS LAST, p."player_name";